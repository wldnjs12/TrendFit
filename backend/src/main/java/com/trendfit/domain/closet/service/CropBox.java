package com.trendfit.domain.closet.service;

/**
 * Vision이 반환하는 크롭 영역. 이미지 전체 크기 대비 0~1 정규화 좌표(좌상단 기준)이다.
 */
public record CropBox(double x, double y, double width, double height) {
}
