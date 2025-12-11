package com.pomodoro_app.demo.services;

import com.pomodoro_app.demo.common.TimeWorker;
import com.pomodoro_app.demo.models.PomodoroSession;
import com.pomodoro_app.demo.models.TaskStatus;
import com.pomodoro_app.demo.models.User;
import com.pomodoro_app.demo.repository.PomodoroRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import com.pomodoro_app.demo.repository.UserRepository;

import java.util.List;

@Service
public class PomodoroService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PomodoroRepository repository;

    @Autowired
    private TimeWorker timeWorker;

    public List<PomodoroSession> findAll() {
        return repository.findAll();
    }

    public PomodoroSession create(PomodoroSession session) {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        
        String username;
        if (principal instanceof UserDetails) {
            username = ((UserDetails)principal).getUsername();
        } else {
            username = principal.toString();
        }
        System.out.println("Nombre de usuario: " + username);

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found on the session"));

        session.setUserId(user.getId());

        session.setStatus(TaskStatus.PENDING);
        session.setNanosAccumulated(0);
        
        return repository.save(session);
    }

    public PomodoroSession update(String id, PomodoroSession sessionDetails) {
        PomodoroSession session = getSession(id);

        if (sessionDetails.getTaskName() != null) {
            session.setTaskName(sessionDetails.getTaskName());
        }

        if (sessionDetails.getDurationMinutes() > 0) {
            session.setDurationMinutes(sessionDetails.getDurationMinutes());
        }

        if (sessionDetails.getStatus() != null) {
            session.setStatus(sessionDetails.getStatus());
        }

        return repository.save(session);
    }

    public PomodoroSession startSession(String id) {
        PomodoroSession session = getSession(id);

        if (session.getStatus() != TaskStatus.IN_PROGRESS) {
            session.setStatus(TaskStatus.IN_PROGRESS);
            session.setStartTime(timeWorker.now());
            repository.save(session);
        }

        return session;
    }

    public PomodoroSession pauseSession(String id) {
        PomodoroSession session = getSession(id);
        
        if (session.getStatus() == TaskStatus.IN_PROGRESS) {
            long deltaNanos = timeWorker.nanosElapsedSince(session.getStartTime());
            session.setNanosAccumulated(session.getNanosAccumulated() + deltaNanos);
            session.setStartTime(null);
            session.setStatus(TaskStatus.PAUSED);
            session.setPauseCount(session.getPauseCount() + 1);
            repository.save(session);
        }
        return session;
    }

    public PomodoroSession skipBreak(String id) {
        PomodoroSession session = getSession(id);
        session.setBreakSkipped(true);
        
        return repository.save(session);
    }

    public PomodoroSession stopSession(String id) {
        PomodoroSession session = getSession(id);

        if (session.getStatus() == TaskStatus.IN_PROGRESS) {
            long deltaNanos = timeWorker.nanosElapsedSince(session.getStartTime());
            session.setNanosAccumulated(session.getNanosAccumulated() + deltaNanos);
        }
        
        session.setStatus(TaskStatus.TERMINATED);
        session.setStartTime(null);
        repository.save(session);

        return session;
    }

    public long getTimeRemainingNanos(String id) {
        PomodoroSession session = getSession(id);

        long totalNanos = session.getDurationMinutes() * 60L * 1_000_000_000L;
        long elapsed = session.getNanosAccumulated();

        if (session.getStatus() == TaskStatus.IN_PROGRESS) {
            elapsed += timeWorker.nanosElapsedSince(session.getStartTime());
        }

        long remaining = totalNanos - elapsed;
        
        return remaining > 0 ? remaining : 0;
    }

    private PomodoroSession getSession(String id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Session not found: " + id));
    }
}