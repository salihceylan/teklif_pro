(function () {
  function isSupported() {
    return (
      typeof window !== 'undefined' &&
      'Notification' in window &&
      'serviceWorker' in navigator &&
      'PushManager' in window &&
      (window.isSecureContext || window.location.hostname === 'localhost')
    );
  }

  function permission() {
    return isSupported() ? Notification.permission : 'unsupported';
  }

  function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding)
      .replace(/-/g, '+')
      .replace(/_/g, '/');
    const rawData = atob(base64);
    return Uint8Array.from([...rawData].map((char) => char.charCodeAt(0)));
  }

  async function ensureRegistration() {
    return navigator.serviceWorker.register('/push_service_worker.js', {
      scope: '/',
    });
  }

  async function fetchJson(url, options) {
    const response = await fetch(url, options);
    let data = null;
    try {
      data = await response.json();
    } catch (_) {
      data = null;
    }
    if (!response.ok) {
      const detail =
        (data && (data.detail || data.message)) ||
        `HTTP ${response.status}`;
      throw new Error(detail);
    }
    return data;
  }

  async function fetchPublicKey(apiBaseUrl, authToken) {
    const data = await fetchJson(`${apiBaseUrl}/notifications/webpush/public-key`, {
      headers: {
        Authorization: `Bearer ${authToken}`,
      },
    });
    return data.public_key;
  }

  function parseSubscription(subscription) {
    const json = subscription.toJSON();
    return {
      endpoint: json.endpoint,
      expiration_time: json.expirationTime || null,
      keys: {
        p256dh: json.keys.p256dh,
        auth: json.keys.auth,
      },
    };
  }

  async function syncSubscription(options) {
    if (!isSupported()) {
      return { success: false, reason: 'unsupported' };
    }

    let currentPermission = Notification.permission;
    if (currentPermission === 'default' && options.requestPermission) {
      currentPermission = await Notification.requestPermission();
    }

    if (currentPermission !== 'granted') {
      return { success: false, reason: currentPermission };
    }

    const registration = await ensureRegistration();
    const publicKey = await fetchPublicKey(
      options.apiBaseUrl,
      options.authToken,
    );
    let subscription = await registration.pushManager.getSubscription();
    if (!subscription) {
      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(publicKey),
      });
    }

    await fetchJson(`${options.apiBaseUrl}/notifications/webpush/subscribe`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${options.authToken}`,
      },
      body: JSON.stringify({
        ...parseSubscription(subscription),
        topics: options.topics || [],
        user_agent: navigator.userAgent,
      }),
    });

    return { success: true };
  }

  async function unsubscribe(options) {
    if (!isSupported()) {
      return { success: false, reason: 'unsupported' };
    }

    const registration = await ensureRegistration();
    const subscription = await registration.pushManager.getSubscription();
    if (!subscription) {
      return { success: true };
    }

    await fetchJson(`${options.apiBaseUrl}/notifications/webpush/unsubscribe`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${options.authToken}`,
      },
      body: JSON.stringify({ endpoint: subscription.endpoint }),
    });

    await subscription.unsubscribe();
    return { success: true };
  }

  async function sendTestPush(options) {
    if (!isSupported()) {
      return { success: false, reason: 'unsupported' };
    }

    await fetchJson(`${options.apiBaseUrl}/notifications/webpush/test`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${options.authToken}`,
      },
    });

    return { success: true };
  }

  window.teklifProPush = {
    isSupported,
    permission,
    syncSubscription,
    unsubscribe,
    sendTestPush,
  };
})();
