package com.trendfit.domain.closet.service;

import javax.imageio.ImageIO;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

/**
 * 폰 카메라로 찍은 원본 사진(수 MB)을 그대로 Claude Vision에 보내면 업로드 시간과 토큰 비용만
 * 늘어난다. Claude가 어차피 내부적으로 다운스케일하는 권장 상한(긴 변 1568px)보다 크면 미리
 * 축소해서 보낸다.
 */
final class ImageDownscaler {

    private static final int MAX_DIMENSION = 1568;

    private ImageDownscaler() {
    }

    /** 디코딩 실패(WebP 등 javax.imageio 미지원 포맷) 시에는 원본을 그대로 반환한다 —
     * 등록 자체가 막혀서는 안 된다(ImageCropper와 동일한 폴백 원칙). */
    static byte[] downscale(byte[] original) {
        try {
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(original));
            if (image == null) {
                return original;
            }

            int width = image.getWidth();
            int height = image.getHeight();
            int longSide = Math.max(width, height);
            if (longSide <= MAX_DIMENSION) {
                return original;
            }

            double scale = (double) MAX_DIMENSION / longSide;
            int targetWidth = Math.max(1, (int) Math.round(width * scale));
            int targetHeight = Math.max(1, (int) Math.round(height * scale));

            Image scaledInstance = image.getScaledInstance(targetWidth, targetHeight, Image.SCALE_SMOOTH);
            BufferedImage resized = new BufferedImage(targetWidth, targetHeight, BufferedImage.TYPE_INT_RGB);
            resized.createGraphics().drawImage(scaledInstance, 0, 0, null);

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            ImageIO.write(resized, "jpg", out);
            return out.toByteArray();
        } catch (IOException | RuntimeException e) {
            return original;
        }
    }
}
