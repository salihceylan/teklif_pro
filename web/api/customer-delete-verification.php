<?php
declare(strict_types=1);

const API_BASE_URL = 'https://teklif.gudeteknoloji.com.tr/api/v1';
const SMTP_HOST = 'mint.trdns.com';
const SMTP_PORT = 587;
const SMTP_USER = 'teklif@gudeteknoloji.com.tr';
const SMTP_PASSWORD = 'Fingon08.';
const SMTP_FROM = 'teklif@gudeteknoloji.com.tr';
const SMTP_FROM_NAME = 'Teklif Pro';
const CODE_EXPIRES_IN = 600;
const RESEND_COOLDOWN = 45;
const MAX_VERIFY_ATTEMPTS = 5;

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(405, ['detail' => 'Yalnızca POST istekleri kabul edilir']);
}

try {
    $payload = json_decode(file_get_contents('php://input') ?: '[]', true);
    if (!is_array($payload)) {
        respond(400, ['detail' => 'Geçersiz istek gövdesi']);
    }

    purgeExpiredChallenges();

    $action = trim((string) ($payload['action'] ?? ''));
    if ($action === 'send') {
        handleSend($payload);
    }
    if ($action === 'verify_delete') {
        handleVerifyDelete($payload);
    }

    respond(400, ['detail' => 'Geçersiz işlem']);
} catch (Throwable $exception) {
    respond(500, ['detail' => 'Doğrulama servisi şu anda kullanılamıyor']);
}

function handleSend(array $payload): void
{
    $authToken = requireString($payload, 'auth_token');
    $customerId = requirePositiveInt($payload, 'customer_id');
    $companyName = requireString($payload, 'company_name');

    $user = apiRequest('GET', '/auth/me', $authToken);
    $email = strtolower(trim((string) ($user['email'] ?? '')));
    $userId = (int) ($user['id'] ?? 0);

    if ($userId <= 0 || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        respond(422, ['detail' => 'Doğrulama için geçerli kullanıcı e-postası bulunamadı']);
    }

    enforceResendCooldown($userId, $customerId);

    $code = str_pad((string) random_int(0, 9999), 4, '0', STR_PAD_LEFT);
    $requestId = bin2hex(random_bytes(16));
    $now = time();

    $record = [
        'request_id' => $requestId,
        'user_id' => $userId,
        'user_email' => $email,
        'customer_id' => $customerId,
        'company_name' => $companyName,
        'code_hash' => password_hash($code, PASSWORD_DEFAULT),
        'attempts' => 0,
        'expires_at' => $now + CODE_EXPIRES_IN,
        'created_at' => $now,
    ];

    saveJson(challengePath($requestId), $record);
    saveJson(throttlePath($userId, $customerId), ['available_at' => $now + RESEND_COOLDOWN]);

    sendVerificationMail($email, $companyName, $code);

    respond(200, [
        'request_id' => $requestId,
        'masked_email' => maskEmail($email),
        'expires_in' => CODE_EXPIRES_IN,
        'resend_after' => RESEND_COOLDOWN,
    ]);
}

function handleVerifyDelete(array $payload): void
{
    $authToken = requireString($payload, 'auth_token');
    $requestId = requireRequestId($payload, 'request_id');
    $code = trim((string) ($payload['code'] ?? ''));

    if (!preg_match('/^\d{4}$/', $code)) {
        respond(422, ['detail' => '4 haneli doğrulama kodu girin']);
    }

    $path = challengePath($requestId);
    $record = readJson($path);
    if ($record === null) {
        respond(404, ['detail' => 'Doğrulama oturumu bulunamadı']);
    }

    if ((int) ($record['expires_at'] ?? 0) < time()) {
        @unlink($path);
        respond(410, ['detail' => 'Doğrulama kodunun süresi doldu']);
    }

    $user = apiRequest('GET', '/auth/me', $authToken);
    $email = strtolower(trim((string) ($user['email'] ?? '')));
    $userId = (int) ($user['id'] ?? 0);

    if ($userId !== (int) ($record['user_id'] ?? 0) || $email !== (string) ($record['user_email'] ?? '')) {
        respond(403, ['detail' => 'Bu doğrulama kodu mevcut oturumla eşleşmiyor']);
    }

    $attempts = (int) ($record['attempts'] ?? 0) + 1;
    $record['attempts'] = $attempts;

    if (!password_verify($code, (string) ($record['code_hash'] ?? ''))) {
        if ($attempts >= MAX_VERIFY_ATTEMPTS) {
            @unlink($path);
            respond(422, ['detail' => 'Kod yanlış girildi. Güvenlik nedeniyle yeni kod isteyin']);
        }
        saveJson($path, $record);
        respond(422, ['detail' => 'Doğrulama kodu hatalı']);
    }

    $customerId = (int) ($record['customer_id'] ?? 0);
    $impact = inspectDependencies($customerId, $authToken);
    cascadeDelete($customerId, $impact, $authToken);

    @unlink($path);
    @unlink(throttlePath($userId, $customerId));

    respond(200, ['impact' => $impact]);
}

function inspectDependencies(int $customerId, string $authToken): array
{
    $invoices = filterByCustomer(apiRequest('GET', '/invoices/', $authToken), $customerId);
    $visits = filterByCustomer(apiRequest('GET', '/visits/', $authToken), $customerId);
    $quotes = filterByCustomer(apiRequest('GET', '/quotes/', $authToken), $customerId);
    $serviceRequests = filterByCustomer(apiRequest('GET', '/service-requests/', $authToken), $customerId);

    return [
        'invoice_ids' => array_column($invoices, 'id'),
        'visit_ids' => array_column($visits, 'id'),
        'quote_ids' => array_column($quotes, 'id'),
        'service_request_ids' => array_column($serviceRequests, 'id'),
        'invoice_count' => count($invoices),
        'visit_count' => count($visits),
        'quote_count' => count($quotes),
        'service_request_count' => count($serviceRequests),
    ];
}

function cascadeDelete(int $customerId, array $impact, string $authToken): void
{
    foreach ($impact['invoice_ids'] as $invoiceId) {
        apiRequest('DELETE', '/invoices/' . (int) $invoiceId, $authToken);
    }
    foreach ($impact['visit_ids'] as $visitId) {
        apiRequest('DELETE', '/visits/' . (int) $visitId, $authToken);
    }
    foreach ($impact['quote_ids'] as $quoteId) {
        apiRequest('DELETE', '/quotes/' . (int) $quoteId, $authToken);
    }
    foreach ($impact['service_request_ids'] as $requestId) {
        apiRequest('DELETE', '/service-requests/' . (int) $requestId, $authToken);
    }

    apiRequest('DELETE', '/customers/' . $customerId, $authToken);
}

function filterByCustomer(array $items, int $customerId): array
{
    return array_values(array_filter(
        $items,
        static fn(array $item): bool => (int) ($item['customer_id'] ?? 0) === $customerId
    ));
}

function apiRequest(string $method, string $path, string $authToken, ?array $payload = null): array
{
    if (!function_exists('curl_init')) {
        respond(500, ['detail' => 'Sunucuda cURL desteği bulunamadı']);
    }

    $ch = curl_init(API_BASE_URL . $path);
    $headers = [
        'Accept: application/json',
        'Authorization: Bearer ' . $authToken,
    ];

    if ($payload !== null) {
        $json = json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        $headers[] = 'Content-Type: application/json';
        curl_setopt($ch, CURLOPT_POSTFIELDS, $json);
    }

    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_TIMEOUT => 60,
        CURLOPT_CONNECTTIMEOUT => 15,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2,
    ]);

    $response = curl_exec($ch);
    if ($response === false) {
        $error = curl_error($ch);
        curl_close($ch);
        respond(502, ['detail' => 'API bağlantısı kurulamadı: ' . $error]);
    }

    $status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    curl_close($ch);

    $decoded = $response === '' ? [] : json_decode($response, true);
    if ($status < 200 || $status >= 300) {
        $detail = is_array($decoded) && isset($decoded['detail'])
            ? (string) $decoded['detail']
            : 'API işlemi başarısız oldu';
        respond($status >= 400 && $status < 600 ? $status : 502, ['detail' => $detail]);
    }

    return is_array($decoded) ? $decoded : [];
}

function sendVerificationMail(string $recipient, string $companyName, string $code): void
{
    $subject = 'Firma silme doğrulama kodunuz';
    $body = implode("\n", [
        'Merhaba,',
        '',
        $companyName . ' firması ve bağlı kayıtlarını silme işlemi için doğrulama kodunuz:',
        '',
        'Kod: ' . $code,
        '',
        'Kod 10 dakika boyunca geçerlidir. Bu işlemi siz başlatmadıysanız lütfen dikkate almayın.',
        '',
        'Teklif Pro',
    ]);

    smtpSendPlainTextMail($recipient, $subject, $body);
}

function smtpSendPlainTextMail(string $recipient, string $subject, string $body): void
{
    $socket = stream_socket_client(
        'tcp://' . SMTP_HOST . ':' . SMTP_PORT,
        $errno,
        $errstr,
        30
    );

    if (!$socket) {
        respond(502, ['detail' => 'Mail sunucusuna bağlanılamadı']);
    }

    stream_set_timeout($socket, 30);

    expectSmtpResponse($socket, [220]);
    smtpCommand($socket, 'EHLO gudeteknoloji.com.tr', [250]);
    smtpCommand($socket, 'STARTTLS', [220]);

    if (!stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLS_CLIENT)) {
        fclose($socket);
        respond(502, ['detail' => 'Mail güvenli bağlantısı başlatılamadı']);
    }

    smtpCommand($socket, 'EHLO gudeteknoloji.com.tr', [250]);
    smtpCommand($socket, 'AUTH LOGIN', [334]);
    smtpCommand($socket, base64_encode(SMTP_USER), [334]);
    smtpCommand($socket, base64_encode(SMTP_PASSWORD), [235]);
    smtpCommand($socket, 'MAIL FROM:<' . SMTP_FROM . '>', [250]);
    smtpCommand($socket, 'RCPT TO:<' . $recipient . '>', [250, 251]);
    smtpCommand($socket, 'DATA', [354]);

    $encodedSubject = '=?UTF-8?B?' . base64_encode($subject) . '?=';
    $headers = [
        'Date: ' . date(DATE_RFC2822),
        'From: ' . formatMailbox(SMTP_FROM, SMTP_FROM_NAME),
        'To: ' . formatMailbox($recipient, $recipient),
        'Subject: ' . $encodedSubject,
        'MIME-Version: 1.0',
        'Content-Type: text/plain; charset=UTF-8',
        'Content-Transfer-Encoding: 8bit',
    ];

    $message = implode("\r\n", $headers) . "\r\n\r\n" . normalizeSmtpBody($body) . "\r\n.\r\n";
    fwrite($socket, $message);
    expectSmtpResponse($socket, [250]);
    smtpCommand($socket, 'QUIT', [221]);
    fclose($socket);
}

function smtpCommand($socket, string $command, array $expectedCodes): void
{
    fwrite($socket, $command . "\r\n");
    expectSmtpResponse($socket, $expectedCodes);
}

function expectSmtpResponse($socket, array $expectedCodes): void
{
    $response = '';
    while (($line = fgets($socket, 515)) !== false) {
        $response .= $line;
        if (strlen($line) < 4 || $line[3] === ' ') {
            break;
        }
    }

    $code = (int) substr($response, 0, 3);
    if (!in_array($code, $expectedCodes, true)) {
        fclose($socket);
        respond(502, ['detail' => 'Mail gönderimi başarısız oldu']);
    }
}

function normalizeSmtpBody(string $body): string
{
    $body = str_replace(["\r\n", "\r"], "\n", $body);
    $body = implode(
        "\r\n",
        array_map(
            static fn(string $line): string => substr($line, 0, 1) === '.' ? '.' . $line : $line,
            explode("\n", $body)
        )
    );

    return $body;
}

function formatMailbox(string $email, string $name): string
{
    $encodedName = '=?UTF-8?B?' . base64_encode($name) . '?=';
    return $encodedName . ' <' . $email . '>';
}

function enforceResendCooldown(int $userId, int $customerId): void
{
    $throttle = readJson(throttlePath($userId, $customerId));
    $availableAt = (int) ($throttle['available_at'] ?? 0);
    $remaining = $availableAt - time();
    if ($remaining > 0) {
        respond(429, [
            'detail' => 'Lütfen yeni kod istemeden önce kısa süre bekleyin',
            'resend_after' => $remaining,
        ]);
    }
}

function purgeExpiredChallenges(): void
{
    foreach (glob(storageDir() . DIRECTORY_SEPARATOR . 'challenge-*.json') ?: [] as $file) {
        $data = readJson($file);
        if ($data === null || (int) ($data['expires_at'] ?? 0) < time()) {
            @unlink($file);
        }
    }
}

function storageDir(): string
{
    $dir = rtrim(sys_get_temp_dir(), DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . 'teklif-pro-delete-verifications';
    if (!is_dir($dir) && !mkdir($dir, 0700, true) && !is_dir($dir)) {
        respond(500, ['detail' => 'Doğrulama depolama alanı hazırlanamadı']);
    }

    return $dir;
}

function challengePath(string $requestId): string
{
    return storageDir() . DIRECTORY_SEPARATOR . 'challenge-' . $requestId . '.json';
}

function throttlePath(int $userId, int $customerId): string
{
    return storageDir() . DIRECTORY_SEPARATOR . 'throttle-' . sha1($userId . '|' . $customerId) . '.json';
}

function readJson(string $path): ?array
{
    if (!is_file($path)) {
        return null;
    }

    $contents = file_get_contents($path);
    if ($contents === false || $contents === '') {
        return null;
    }

    $decoded = json_decode($contents, true);
    return is_array($decoded) ? $decoded : null;
}

function saveJson(string $path, array $data): void
{
    $json = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if ($json === false || file_put_contents($path, $json, LOCK_EX) === false) {
        respond(500, ['detail' => 'Doğrulama verisi kaydedilemedi']);
    }
}

function maskEmail(string $email): string
{
    [$localPart, $domain] = explode('@', $email, 2);
    $prefix = substr($localPart, 0, 1);
    return $prefix . str_repeat('*', max(2, strlen($localPart) - 1)) . '@' . $domain;
}

function requireString(array $payload, string $key): string
{
    $value = trim((string) ($payload[$key] ?? ''));
    if ($value === '') {
        respond(422, ['detail' => 'Eksik alan: ' . $key]);
    }

    return $value;
}

function requirePositiveInt(array $payload, string $key): int
{
    $value = (int) ($payload[$key] ?? 0);
    if ($value <= 0) {
        respond(422, ['detail' => 'Geçersiz alan: ' . $key]);
    }

    return $value;
}

function requireRequestId(array $payload, string $key): string
{
    $value = requireString($payload, $key);
    if (!preg_match('/^[a-f0-9]{32}$/', $value)) {
        respond(422, ['detail' => 'Geçersiz doğrulama oturumu']);
    }

    return $value;
}

function respond(int $status, array $payload): void
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}
