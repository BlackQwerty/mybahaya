/// Rewrites raw MinIO object URLs (served on port 9000) to the HTTPS reverse
/// proxy on port 443. Many mobile carriers and WiFi networks block uncommon
/// ports like 9000, which makes raw URLs hang forever ("loading…"). Routing
/// through https://api.mybahaya.com/minio keeps media on port 443, which is
/// never blocked. Safe to call on any URL — non-matching URLs pass through.
String safeMediaUrl(String url) {
  return url.replaceFirst(
    'http://178.105.158.80:9000',
    'https://api.mybahaya.com/minio',
  );
}
