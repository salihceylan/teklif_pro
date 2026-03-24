window.dartPdfJsBaseUrl = 'assets/js/pdf/3.2.146/';
window.dartPdfJsVersion = '3.2.146';

if (window.pdfjsLib && window.pdfjsLib.GlobalWorkerOptions) {
  window.pdfjsLib.GlobalWorkerOptions.workerSrc =
    `${window.dartPdfJsBaseUrl}pdf.worker.min.js`;
}
