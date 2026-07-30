package com.trendfit.global.config;

import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

import java.net.http.HttpClient;
import java.time.Duration;

/**
 * 외부 API 클라이언트(날씨/네이버쇼핑 등)가 쓰는 RestClient는 기본 설정으로는 timeout이 없어
 * 상대 서버가 응답하지 않으면 무한정 대기한다. 각 클라이언트가 자기 상황에 맞는 timeout으로
 * RestClient를 만들 수 있도록 공통 팩토리로 둔다.
 */
public final class TimeoutRestClientFactory {

    private TimeoutRestClientFactory() {
    }

    public static RestClient create(Duration connectTimeout, Duration readTimeout) {
        HttpClient httpClient = HttpClient.newBuilder()
                .connectTimeout(connectTimeout)
                .build();
        JdkClientHttpRequestFactory requestFactory = new JdkClientHttpRequestFactory(httpClient);
        requestFactory.setReadTimeout(readTimeout);
        return RestClient.builder().requestFactory(requestFactory).build();
    }
}
