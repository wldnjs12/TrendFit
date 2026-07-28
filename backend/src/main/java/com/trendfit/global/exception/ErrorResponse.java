package com.trendfit.global.exception;

/** 클라이언트에 노출하는 최소한의 오류 응답. */
public record ErrorResponse(String message) {
}
