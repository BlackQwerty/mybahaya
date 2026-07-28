/// Rewrites raw MinIO object URLs from the old VPS to the local MinIO server.
/// Safe to call on any URL — non-matching URLs pass through unchanged.
String safeMediaUrl(String url) {
  const localMinioUrl = 'http://192.168.0.34:9000';

  return url
      .replaceFirst('http://178.105.158.80:9000', localMinioUrl)
      .replaceFirst('http://minio:9000', localMinioUrl)
      .replaceFirst('http://localhost:9000', localMinioUrl);
}
