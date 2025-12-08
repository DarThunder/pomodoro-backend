package com.pomodoro_app.demo.repository;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;
import com.pomodoro_app.demo.models.PomodoroSession;

@Repository
public interface PomodoroRepository extends MongoRepository<PomodoroSession, String> {
}