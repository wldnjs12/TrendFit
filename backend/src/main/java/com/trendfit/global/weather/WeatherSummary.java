package com.trendfit.global.weather;

/** 오늘의 날씨 요약 — 추천 프롬프트에 그대로 주입할 수 있는 형태로 보관한다. */
public record WeatherSummary(
        String minTemp,
        String maxTemp,
        String condition,
        String precipitationProbability
) {

    public String toPromptText() {
        return String.format("최저 %s°C / 최고 %s°C, %s, 강수확률 %s",
                nullToDash(minTemp), nullToDash(maxTemp), nullToDash(condition),
                precipitationProbability == null ? "-" : precipitationProbability + "%");
    }

    private String nullToDash(String value) {
        return value == null ? "-" : value;
    }
}
