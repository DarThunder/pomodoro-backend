package com.pomodoro_app.demo.controller;

import com.pomodoro_app.demo.dto.UserStatsDTO;
import com.pomodoro_app.demo.models.PomodoroSession;
import com.pomodoro_app.demo.services.PomodoroService;
import com.pomodoro_app.demo.services.StatsService;

import jakarta.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/pomodoros")
@CrossOrigin(origins = "*")
public class PomodoroController {

    @Autowired
    private PomodoroService service;
    @Autowired
    private StatsService statsService;

    @GetMapping
    public List<PomodoroSession> getAllSessions() {
        return service.findAll();
    }

    @PostMapping
    public PomodoroSession createSession(@Valid @RequestBody PomodoroSession session) {
        return service.create(session);
    }

    @PostMapping("/{id}/start")
    public ResponseEntity<PomodoroSession> startTimer(@PathVariable String id) {
        return ResponseEntity.ok(service.startSession(id));
    }

    @PostMapping("/{id}/pause")
    public ResponseEntity<PomodoroSession> pauseTimer(@PathVariable String id) {
        return ResponseEntity.ok(service.pauseSession(id));
    }

    @PostMapping("/{id}/stop")
    public ResponseEntity<PomodoroSession> stopTimer(@PathVariable String id) {
        return ResponseEntity.ok(service.stopSession(id));
    }

    @PostMapping("/{id}/skip-break")
    public ResponseEntity<PomodoroSession> skipBreak(@PathVariable String id) {
        return ResponseEntity.ok(service.startSession(id));
    }

    @GetMapping("/{id}/sync")
    public ResponseEntity<Map<String, Long>> getRealTime(@PathVariable String id) {
        long remainingNanos = service.getTimeRemainingNanos(id);
        return ResponseEntity.ok(Map.of(
            "remainingNanos", remainingNanos,
            "remainingSeconds", remainingNanos / 1_000_000_000L
        ));
    }

    @GetMapping("/stats/{userId}")
    public ResponseEntity<UserStatsDTO> getUserStats(@PathVariable String userId) {
        return ResponseEntity.ok(statsService.getUserStats(userId));
    }
}