package com.trendfit.global.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 서비스 계층에서 던지는 검증/상태 예외를 클라이언트가 읽을 수 있는 메시지로 변환한다.
 * (Spring Boot 기본 동작은 예외 메시지를 응답 본문에 노출하지 않는다 — 이 핸들러가 없으면
 * 클라이언트는 항상 빈 500만 받는다.)
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler({IllegalArgumentException.class, IllegalStateException.class})
    public ResponseEntity<ErrorResponse> handleValidation(RuntimeException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ErrorResponse(e.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpected(Exception e) {
        log.error("[GlobalExceptionHandler] 처리되지 않은 예외", e);
        return ResponseEntity.internalServerError().body(new ErrorResponse("서버에 문제가 발생했습니다. 잠시 후 다시 시도해주세요."));
    }
}
