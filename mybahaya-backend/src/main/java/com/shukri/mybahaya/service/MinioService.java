package com.shukri.mybahaya.service;

import io.minio.BucketExistsArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.SetBucketPolicyArgs;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.UUID;

@Service
public class MinioService {

    @Autowired
    private MinioClient minioClient;

    @Value("${minio.bucket.reports}")
    private String reportsBucket;

    @Value("${minio.url}")
    private String minioUrl;

    @Value("${minio.public-url}")
    private String minioPublicUrl;

    /** Uploads a single image and returns its public URL. */
    public String uploadReportImage(MultipartFile file) throws Exception {
        return uploadFile(file);
    }

    /**
     * Uploads a video as-is (original quality, untouched), returns its public URL.
     * Length is gated by file size on the client + the multipart limit, not by
     * re-encoding — so the uploaded video plays exactly like the user's original.
     */
    public String uploadReportVideo(MultipartFile file) throws Exception {
        return uploadFile(file);
    }

    /** Generic upload — any media file (image or video) → MinIO → public URL. */
    public String uploadFile(MultipartFile file) throws Exception {
        // Ensure bucket exists
        boolean found = minioClient.bucketExists(BucketExistsArgs.builder().bucket(reportsBucket).build());
        if (!found) {
            minioClient.makeBucket(MakeBucketArgs.builder().bucket(reportsBucket).build());
        }
        ensurePublicReadPolicy();

        // Generate unique filename
        String extension = getFileExtension(file.getOriginalFilename());
        String objectName = UUID.randomUUID().toString() + extension;

        // Upload to MinIO
        try (InputStream inputStream = file.getInputStream()) {
            minioClient.putObject(
                PutObjectArgs.builder()
                    .bucket(reportsBucket)
                    .object(objectName)
                    .stream(inputStream, file.getSize(), -1)
                    .contentType(file.getContentType())
                    .build()
            );
        }

        // Return a URL the phone/browser can reach, not the Docker-internal URL.
        return minioPublicUrl + "/" + reportsBucket + "/" + objectName;
    }

    private void ensurePublicReadPolicy() throws Exception {
        String policy = """
            {
              "Version": "2012-10-17",
              "Statement": [
                {
                  "Effect": "Allow",
                  "Principal": "*",
                  "Action": ["s3:GetObject"],
                  "Resource": ["arn:aws:s3:::%s/*"]
                }
              ]
            }
            """.formatted(reportsBucket);

        minioClient.setBucketPolicy(
            SetBucketPolicyArgs.builder()
                .bucket(reportsBucket)
                .config(policy)
                .build()
        );
    }

    private String getFileExtension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return ".jpg";
        }
        return filename.substring(filename.lastIndexOf("."));
    }
}
