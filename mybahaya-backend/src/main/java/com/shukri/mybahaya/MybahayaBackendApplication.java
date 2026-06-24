package com.shukri.mybahaya;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class MybahayaBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(MybahayaBackendApplication.class, args);
		System.out.println("========================================");
		System.out.println("  MYBAHAYA_BUILD: video-original-v4");
		System.out.println("========================================");
	}

}
