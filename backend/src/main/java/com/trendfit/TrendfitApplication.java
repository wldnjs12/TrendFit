package com.trendfit;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * TrendFit 백엔드 진입점.
 *
 * 트렌드 수집 배치({@link com.trendfit.domain.trend.TrendCollectionScheduler})를
 * 애플리케이션 레벨 스케줄러로 실행하기 위해 @EnableScheduling 을 활성화한다.
 */
@EnableScheduling
@SpringBootApplication
public class TrendfitApplication {

    public static void main(String[] args) {
        SpringApplication.run(TrendfitApplication.class, args);
    }
}
