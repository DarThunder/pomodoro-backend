# Changelog

## Alpha

### v0.1.0

#### Initial Release

- **Project Scaffolding:** Initialized Spring Boot 4.0.0 project with Java 17 and MongoDB drivers.
- **Domain Modeling:** Defined core entities (`User`, `PomodoroSession`) and their respective Repositories.
- **Basic CRUD:** Implemented the first version of `PomodoroController` for basic session creation and retrieval.

## Beta

### v0.9.0

#### Core

- **Time Engine (`TimeWorker`):** Introduced a custom component to calculate time deltas based on `System.nanoTime()`. This decouples the business logic from the system clock, preventing "time drift" issues and enabling "Time Travel" for unit testing.
- **State Machine:** implemented the strict transition logic (`PENDING` -> `IN_PROGRESS` -> `PAUSED` -> `TERMINATED`) to ensure session integrity.

#### Security

- **Stateless Authentication:** Migrated from basic session storage to a fully stateless **JWT** architecture.
- **Cookie Security:** Implemented `HttpOnly` and `Secure` cookie strategies for token delivery, mitigating the risk of XSS attacks inherent in `localStorage` implementations.

## Production

### v1.0.0

**"The Enterprise Release"**

This release marks the transition from development to a production-ready system. It incorporates the feedback from the "Chaos Protocol" testing phase, finalizing the resilience and security layers for cloud deployment.

#### Architecture & DevOps

- **Docker Multi-Stage Build:** Refactored the `Dockerfile` to use a two-step build process (`maven:alpine` -> `eclipse-temurin:alpine`). This eliminates the dependency on local `target/` folders and reduces the final image size by ~70% while ensuring build reproducibility in the cloud.
- **Dynamic Configuration:** Implemented a robust `application.properties` system that intelligently switches between local defaults and Cloud Environment Variables (`PORT`, `JWT_SECRET`, `SPRING_DATA_MONGODB_URI`).
- **CORS Strategy:** Centralized Cross-Origin Resource Sharing configuration in `SecurityConfig` to support dynamic frontend URLs via environment variables, ensuring smooth integration with external clients.

#### Security & Resilience

- **Chaos Hardening:** Addressed vulnerabilities exposed during the _Machine Gun Test_. The system now gracefully handles high-concurrency bursts (20+ req/sec) without database locking.
- **Validation Sanitization:** Overhauled `GlobalExceptionHandler` to catch `MethodArgumentNotValidException`. Validation errors (e.g., negative duration) now return a clean `400 Bad Request` with specific field errors instead of a generic `403 Forbidden` or raw stack traces.
- **Entropy Upgrade:** Upgraded the JWT signing key requirement to strictly enforce 256-bit entropy (minimum 32 bytes), compatible with `HS256` standards.

#### Fixes

- **Stats Service Patch:** Fixed a bug in the Aggregation Pipeline where the `UserStatsDTO` returned a `null` userId. The service now correctly maps the requested user ID to the response object.
- **Dependency Injection:** Resolved an `UnsatisfiedDependencyException` by implementing a dedicated `UserDetailsServiceImpl` to bridge the gap between Spring Security and the MongoDB `UserRepository`.

### v1.1.0

**"The Flexibility Update"**

Based on developer feedback and team requirements, this update introduces session mutability and improves the local development experience.

#### Features

- **Session Editing:** Introduced the `PUT /api/pomodoros/{id}` endpoint. Users can now modify session details (Task Name, Duration, and Status) post-creation, offering greater flexibility for correcting mistakes or adjusting workflows manually.

#### Fixes & Improvements

- **Localhost Compatibility:** Patched `JwtUtils` to support non-HTTPS environments by implementing dynamic Cookie Security (`Secure=true`, `SameSite=None`) when running in development mode. This resolves authentication issues previously encountered on `localhost`.
- **Documentation:** Updated README and Wiki tables to reflect the new API capabilities and ensure the documentation matches the current state of the codebase.
