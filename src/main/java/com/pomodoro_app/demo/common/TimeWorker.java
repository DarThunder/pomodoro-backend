package com.pomodoro_app.demo.common;

import org.springframework.stereotype.Component;
import java.time.Clock;
import java.time.Instant;

@Component
public class TimeWorker {

    private final Clock clock;

    public TimeWorker() {
        this.clock = Clock.systemUTC();
    }

    public Instant now() {
        return Instant.now(clock);
    }

    public long nanosElapsedSince(Instant start) {
        if (start == null) return 0;
        Instant current = now();
        long secDiff = current.getEpochSecond() - start.getEpochSecond();
        long nanoDiff = current.getNano() - start.getNano();
        
        return (secDiff * 1_000_000_000L) + nanoDiff;
    }
}