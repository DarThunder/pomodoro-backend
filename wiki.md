# Pomodoro Enterprise Architecture Wiki

## Introduction

**Pomodoro API - Enterprise Edition** is a high-performance backend designed to manage productivity sessions with millisecond precision. It implements a strict **3-Layer Architecture** and **Bank-Grade Security** to ensure data integrity and user privacy.

> _"Scalability first. If it can't handle the chaos, it can't handle production."_

## Architectural Design

### The 3-Layer Model

The system enforces a strict separation of concerns to maintain maintainability and testability:

1.  **Presentation Layer (`Controllers`):** Handles HTTP requests, input validation (`@Valid`), and response formatting. It never contains business logic.
2.  **Service Layer (`Services`):** The core brain. Handles the state machine (`PENDING` -> `IN_PROGRESS`), time calculations (`TimeWorker`), and user statistics.
3.  **Data Access Layer (`Repositories`):** Interfaces with MongoDB using `MongoRepository` and custom Aggregation Pipelines.

### The Time Engine (`TimeWorker`)

Unlike standard implementations that rely on system uptime, this API uses a custom `TimeWorker` component that:

- Calculates deltas using `Instant` and `nanoTime`.
- Prevents "time drift" during server restarts or container pauses.
- Allows for "Time Traveling" during unit tests.

## Security Specification

### Authentication Protocol (Stateless)

We moved away from `localStorage` tokens to a more secure, cookie-based approach.

| Component      | Specification     | Description                                                        |
| :------------- | :---------------- | :----------------------------------------------------------------- |
| **Token Type** | JWT (JWS)         | HMAC-SHA256 (HS256) signed token.                                  |
| **Storage**    | `HttpOnly` Cookie | Inaccessible to JavaScript (prevents XSS).                         |
| **Transport**  | `Secure` Flag     | Only sent over HTTPS (or localhost).                               |
| **CSRF**       | Disabled          | Not required for stateless APIs (SessionCreationPolicy.STATELESS). |
| **CORS**       | Dynamic           | Configurable via `FRONTEND_URL` env var.                           |

### Access Control

- **Public Endpoints:** `/api/auth/**` (Register, Login).
- **Protected Endpoints:** `/api/pomodoros/**` (Requires valid Cookie).

## API Reference

### Auth Module

| Endpoint             | Method | Payload / Description                                     |
| :------------------- | :----- | :-------------------------------------------------------- |
| `/api/auth/register` | `POST` | `{"username": "user", "password": "***", "email": "..."}` |
| `/api/auth/login`    | `POST` | Returns `200 OK` + `Set-Cookie` header.                   |
| `/api/auth/logout`   | `POST` | Clears the auth cookie.                                   |

### Pomodoro Lifecycle

The session state machine moves through specific transitions:

| Endpoint              | Method   | Transition                         | Description                                       |
| :-------------------- | :------- | :--------------------------------- | :------------------------------------------------ |
| `/api/pomodoros`      | `POST`   | `NULL` → `PENDING`                 | Creates a session configuration.                  |
| `/api/pomodoros/{id}` | `PUT`    | `*` → `*` (Manual)                 | Updates session details (Name, Duration, Status). |
| `/api/pomodoros/{id}` | `DELETE` | `*` → `NULL`                       | Permanently removes the session from DB.          |
| `.../{id}/start`      | `POST`   | `PENDING`/`PAUSED` → `IN_PROGRESS` | Starts/Resumes the timer.                         |
| `.../{id}/pause`      | `POST`   | `IN_PROGRESS` → `PAUSED`           | Stops timer, accumulates time.                    |
| `.../{id}/stop`       | `POST`   | `*` → `TERMINATED`                 | Finalizes the session permanently.                |
| `.../{id}/skip-break` | `POST`   | `*` → `*` (Flag Update)            | Marks the break as skipped.                       |

### Real-time & Stats

- **Sync:** `GET /api/pomodoros/{id}/sync` returns `remainingNanos`.
- **Stats:** `GET /api/pomodoros/stats/{userId}` uses MongoDB Aggregations to calculate:
  - Total Focus Time.
  - Total Interruptions.
  - Average Session Length.

## Chaos Engineering Report

The system was subjected to the `chaos_test.sh` protocol.

### 1. Security Penetration

- **Unauthorized Access:** Requests without cookies were rejected with `403 Forbidden`.
- **Brute Force:** Invalid credentials resulted in `401 Unauthorized`.

### 2. Input Fuzzing

- **Negative Time:** Payload `{"durationMinutes": -5}` triggered a `400 Bad Request` with sanitized error messages.
- **Corrupt JSON:** Handled gracefully without exposing stack traces.

### 3. Load Testing ("The Machine Gun")

- **Scenario:** Creation of 20 concurrent sessions in a burst.
- **Result:** **100% Success Rate**.
- **Latency:** ~450ms total execution time.
- **Conclusion:** The connection pool and Thread execution handled the concurrency without locking the database.

## Deployment Guide

### Environment Variables

| Variable                  | Required | Description                                     |
| :------------------------ | :------- | :---------------------------------------------- |
| `SPRING_DATA_MONGODB_URI` | **YES**  | Target MongoDB instance (Atlas Recommended).    |
| `JWT_SECRET`              | **YES**  | 256-bit base64 encoded string.                  |
| `PORT`                    | No       | Default: `8080`.                                |
| `COOKIE_SAME_SITE`        | No       | Default: `Strict`. Use `None` for cross-domain. |

### Docker Strategy

We use a **Multi-Stage Build** to keep the production image minimal.

1.  **Build Stage:** Uses `maven:alpine` to compile source code.
2.  **Runtime Stage:** Uses `eclipse-temurin:alpine` (JRE only) to run the JAR.
3.  **Result:** A lightweight image (~180MB) vs a full JDK image (~600MB).

## Future Extensions

- **WebSockets:** Real-time push notifications for timer completion.
- **Teams:** Shared leaderboards and group sessions.
- **Payment Integration:** Stripe integration for "Premium Focus" features.
