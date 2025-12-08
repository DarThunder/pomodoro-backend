package com.pomodoro_app.demo.dto;

import lombok.Data;

@Data
public class UserStatsDTO {
    private String userId;
    private long totalSessions;
    private long totalMinutesFocus;
    private long totalInterruptions;
    private long totalSkippedBreaks;
    
    public double getAverageInterruptions() {
        return totalSessions == 0 ? 0 : (double) totalInterruptions / totalSessions;
    }
}