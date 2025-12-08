package com.pomodoro_app.demo.models;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.Instant;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Min;

@Data
@Document(collection = "sessions")
public class PomodoroSession {
    @Id
    private String id;
    private String userId;

    @NotBlank(message = "Task name is obligatory")
    private String taskName;
    @Min(value = 1, message = "Duration must be at least 1 minute")
    private int durationMinutes;
    
    private TaskStatus status = TaskStatus.PENDING;
    private int pauseCount = 0;
    private boolean breakSkipped = false;
    
    private Instant startTime; 
    private long nanosAccumulated = 0; 

    @CreatedDate
    private Instant createdAt;
}