package com.example.devopssample;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;

@SpringBootApplication
@RestController
public class DevopsSampleApplication {

    public static void main(String[] args) {
        SpringApplication.run(DevopsSampleApplication.class, args);
    }

    @GetMapping("/")
    public String hello() {
        return "Welcome to CloudWave API - Your Modern Microservice!";
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}
