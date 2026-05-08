package co.edu.uceva.microservicioplanilla.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3ClientBuilder;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

import java.net.URI;

@Configuration
public class S3Config {

    @Value("${s3.endpoint:}")
    private String endpoint;

    @Value("${s3.access-key:}")
    private String accessKey;

    @Value("${s3.secret-key:}")
    private String secretKey;

    @Value("${s3.region:us-east-1}")
    private String region;

    @Bean
    public S3Client s3Client() {
        AwsBasicCredentials creds = AwsBasicCredentials.create(accessKey, secretKey);

        S3Configuration s3Configuration = S3Configuration.builder()
                .pathStyleAccessEnabled(true)
                .build();

        S3ClientBuilder builder = S3Client.builder()
                .credentialsProvider(StaticCredentialsProvider.create(creds))
                .region(Region.of(region))
                .serviceConfiguration(s3Configuration)
                .httpClientBuilder(UrlConnectionHttpClient.builder());

        if (endpoint != null && !endpoint.isBlank()) {
            builder.endpointOverride(URI.create(endpoint));
        }

        return builder.build();
    }

    @Bean
    public S3Presigner s3Presigner() {
        AwsBasicCredentials creds = AwsBasicCredentials.create(accessKey, secretKey);

        S3Presigner.Builder builder = S3Presigner.builder()
                .credentialsProvider(StaticCredentialsProvider.create(creds))
                .region(Region.of(region));

        if (endpoint != null && !endpoint.isBlank()) {
            builder.endpointOverride(URI.create(endpoint));
        }

        return builder.build();
    }
}
