package com.trendfit.domain.closet.service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;

/**
 * Vision이 반환한 정규화(0~1) 크롭 좌표를 실제 픽셀 좌표로 변환해 이미지를 자른다.
 * 배경 제거(누끼)는 하지 않는다 — 크롭까지만 처리한다(service-policy.md §2).
 */
final class ImageCropper {

    private ImageCropper() {
    }

    static byte[] crop(byte[] original, CropBox box) {
        try {
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(original));
            if (image == null) {
                throw new IllegalArgumentException("이미지를 디코딩할 수 없음");
            }

            int x = clamp((int) Math.round(box.x() * image.getWidth()), 0, image.getWidth() - 1);
            int y = clamp((int) Math.round(box.y() * image.getHeight()), 0, image.getHeight() - 1);
            int width = clamp((int) Math.round(box.width() * image.getWidth()), 1, image.getWidth() - x);
            int height = clamp((int) Math.round(box.height() * image.getHeight()), 1, image.getHeight() - y);

            BufferedImage cropped = image.getSubimage(x, y, width, height);

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            ImageIO.write(cropped, "png", out);
            return out.toByteArray();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(value, max));
    }
}
