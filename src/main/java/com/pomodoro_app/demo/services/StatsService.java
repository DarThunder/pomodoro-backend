package com.pomodoro_app.demo.services;

import com.pomodoro_app.demo.dto.UserStatsDTO;
import com.pomodoro_app.demo.models.TaskStatus;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.aggregation.Aggregation;
import org.springframework.data.mongodb.core.aggregation.AggregationResults;
import org.springframework.data.mongodb.core.aggregation.ConditionalOperators;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.stereotype.Service;

import static org.springframework.data.mongodb.core.aggregation.Aggregation.*;

@Service
public class StatsService {

    @Autowired
    private MongoTemplate mongoTemplate;

    public UserStatsDTO getUserStats(String userId) {
        
        Aggregation aggregation = newAggregation(
            match(Criteria.where("userId").is(userId).and("status").is(TaskStatus.TERMINATED.name())),
            group("userId")
                .count().as("totalSessions")
                .sum("durationMinutes").as("totalMinutesFocus")
                .sum("pauseCount").as("totalInterruptions")
                .sum(
                    ConditionalOperators.when(Criteria.where("breakSkipped").is(true))
                        .then(1)
                        .otherwise(0)
                ).as("totalSkippedBreaks")
        );

        AggregationResults<UserStatsDTO> results = mongoTemplate.aggregate(
            aggregation, "sessions", UserStatsDTO.class
        );

        UserStatsDTO stats = results.getUniqueMappedResult();
        if (stats != null) {
            stats.setUserId(userId);
        }
        return stats;
    }
}