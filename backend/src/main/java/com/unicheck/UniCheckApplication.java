package com.unicheck;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class UniCheckApplication {

    public static void main(String[] args) {
        SpringApplication.run(UniCheckApplication.class, args);
    }
}
