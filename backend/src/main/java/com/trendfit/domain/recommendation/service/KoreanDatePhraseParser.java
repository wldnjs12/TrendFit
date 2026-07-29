package com.trendfit.domain.recommendation.service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * 추천 요청문("내일 뭐 입지?", "이번주 수요일에 소개팅 있는데" 등)에서 상대 날짜 표현을 해석해
 * 캘린더에 기록할 날짜(forDate)를 계산한다. 표현이 없으면 오늘 날짜를 그대로 쓴다.
 *
 * "다음주 X요일"이 아닌 단독 요일명("수요일")은 가장 가까운 해당 요일(오늘 포함, 이미 지난
 * 이번주 요일이면 다음주)로 해석한다 — "수요일에 입을 옷 추천해줘"를 화요일에 물으면 내일(이번주
 * 수요일)을, 목요일에 물으면 다음주 수요일을 뜻하는 일상적 화법에 맞춘다.
 */
public final class KoreanDatePhraseParser {

    private static final Pattern NEXT_WEEK_PREFIX = Pattern.compile("다음\\s*주");

    private static final Map<String, DayOfWeek> WEEKDAYS = new LinkedHashMap<>();

    static {
        WEEKDAYS.put("월요일", DayOfWeek.MONDAY);
        WEEKDAYS.put("화요일", DayOfWeek.TUESDAY);
        WEEKDAYS.put("수요일", DayOfWeek.WEDNESDAY);
        WEEKDAYS.put("목요일", DayOfWeek.THURSDAY);
        WEEKDAYS.put("금요일", DayOfWeek.FRIDAY);
        WEEKDAYS.put("토요일", DayOfWeek.SATURDAY);
        WEEKDAYS.put("일요일", DayOfWeek.SUNDAY);
    }

    private KoreanDatePhraseParser() {
    }

    public static LocalDate resolve(String requestText, LocalDate today) {
        if (requestText == null || requestText.isBlank()) {
            return today;
        }
        if (requestText.contains("모레")) {
            return today.plusDays(2);
        }
        if (requestText.contains("내일")) {
            return today.plusDays(1);
        }

        boolean nextWeek = NEXT_WEEK_PREFIX.matcher(requestText).find();
        for (Map.Entry<String, DayOfWeek> entry : WEEKDAYS.entrySet()) {
            if (requestText.contains(entry.getKey())) {
                return resolveWeekday(today, entry.getValue(), nextWeek);
            }
        }

        // "오늘" 명시 여부와 무관하게, 별다른 날짜 표현이 없으면 오늘로 취급한다.
        return today;
    }

    private static LocalDate resolveWeekday(LocalDate today, DayOfWeek target, boolean forceNextWeek) {
        int daysUntil = Math.floorMod(target.getValue() - today.getDayOfWeek().getValue(), 7);
        return forceNextWeek ? today.plusDays(daysUntil + 7) : today.plusDays(daysUntil);
    }
}
