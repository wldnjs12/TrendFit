package com.trendfit.domain.trend.controller;

import com.trendfit.domain.trend.dto.TrendArticleResponse;
import com.trendfit.domain.trend.service.TrendReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** 홈 화면 "트렌드 리포트" 갤러리 API. */
@RestController
@RequestMapping("/api/trends")
@RequiredArgsConstructor
public class TrendController {

    private final TrendReportService trendReportService;

    @GetMapping("/report")
    public List<TrendArticleResponse> getReport() {
        return trendReportService.getReport();
    }
}
