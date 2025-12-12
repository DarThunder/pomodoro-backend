# Pomodoro API - Enterprise Edition

![State: Production Ready](https://img.shields.io/badge/State-Production_Ready-green) ![Java](https://img.shields.io/badge/Java-17-orange) ![Spring Boot](https://img.shields.io/badge/Spring_Boot-4.0.0-brightgreen) ![Docker](https://img.shields.io/badge/Docker-Multi__Stage-blue)

**The definitive backend for time and productivity management.**

> _"Time is money... but my API handles nanoseconds."_

**Pomodoro API** brings the robustness, security, and scalability of an enterprise architecture to the world of the Pomodoro technique. Unlike simple CRUDs, this system implements a strict **3-Layer Architecture**, bank-grade security with JWT in HttpOnly Cookies, and a high-precision time engine capable of withstanding adverse network conditions.

It serves as the core of your productivity infrastructure, ensuring that user sessions, their statistics, and their privacy are safeguarded under the highest industry standards.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage (API Endpoints)](#usage-api-endpoints)
  - [Auth Module](#auth-module)
  - [Pomodoro Module](#pomodoro-module)
- [Architecture & Resilience](#architecture--resilience)
- [FAQ](#faq)
- [License](#license)

## Features

- **True Layered Architecture**: Strict separation of responsibilities (Controller ↔ Service ↔ Repository), meeting the most demanding academic and professional standards.
- **Bank-Grade Security**: Authentication via **JWT** stored in `HttpOnly` and `Secure` Cookies. Immune to common XSS attacks found with `localStorage`.
- **Chaos Proof**: Tested with stress scripts ("The Machine Gun Test"), handling bursts of concurrent transactions and validating malicious inputs without exposing stack traces.
- **Smart Time Engine**: Custom time engine (`TimeWorker`) that calculates deltas in nanoseconds, independent of the container's operating system clock.
- **Docker Native**: Optimized deployment with **Multi-stage builds**, reducing the final image size by containing only the JRE and the compiled JAR.
- **Database Agnostic**: Designed to connect to remote clusters (MongoDB Atlas) or local instances interchangeably.

## Installation

To deploy **Pomodoro API** in your local environment or server, run the following magical command:

```bash
docker-compose up --build
```

_Note: This will start both the Spring Boot service (Port 8080) and a local MongoDB instance (Port 27017) if an external one is not defined._

## Configuration

The system follows the **12-Factor App** methodology. Configure these environment variables in your deployment platform (Railway/Render) or in your `.env`.

| Variable                  | Description                     | Default (Dev)                          |
| :------------------------ | :------------------------------ | :------------------------------------- |
| `SPRING_DATA_MONGODB_URI` | MongoDB Connection String       | `mongodb://mongo-db:27017/pomodoro_db` |
| `JWT_SECRET`              | HS256 master key (min 32 bytes) | _(Auto-generated in Dev)_              |
| `FRONTEND_URL`            | Allowed origin for CORS         | `http://localhost:5500`                |
| `PORT`                    | Server listening port           | `8080`                                 |
| `COOKIE_SAME_SITE`        | Cookie policy (Strict/None)     | `None`                                 |

## Usage (API Endpoints)

The syntax is designed to be RESTful and predictable.

### Auth Module

| Method   | Endpoint             | Description                                    | Required Body                              |
| :------- | :------------------- | :--------------------------------------------- | :----------------------------------------- |
| **POST** | `/api/auth/register` | Creates a new user account.                    | `{ "username": "...", "password": "..." }` |
| **POST** | `/api/auth/login`    | Logs in and sets the secure Cookie.            | `{ "username": "...", "password": "..." }` |
| **POST** | `/api/auth/logout`   | Invalidates the session and clears the cookie. | _N/A_                                      |

### Pomodoro Module

| Method     | Endpoint                         | Description                               | Body / Params                                    |
| :--------- | :------------------------------- | :---------------------------------------- | :----------------------------------------------- |
| **POST**   | `/api/pomodoros`                 | Creates a new focus session.              | `{ "taskName": "Dev", "durationMinutes": 25 }`   |
| **PUT**    | `/api/pomodoros/{id}`            | Updates session details.                  | `{ "taskName": "Fix", "status": "IN_PROGRESS" }` |
| **DELETE** | `/api/pomodoros/{id}`            | Deletes a session permanently.            | _Path Variable ID_                               |
| **POST**   | `/api/pomodoros/{id}/start`      | Starts the timer for a session.           | _Path Variable ID_                               |
| **POST**   | `/api/pomodoros/{id}/pause`      | Pauses the timer and accumulates time.    | _Path Variable ID_                               |
| **POST**   | `/api/pomodoros/{id}/stop`       | Ends the session prematurely.             | _Path Variable ID_                               |
| **POST**   | `/api/pomodoros/{id}/skip-break` | Skips the break and resumes focus.        | _Path Variable ID_                               |
| **GET**    | `/api/pomodoros/{id}/sync`       | Gets the remaining time (in nanoseconds). | _Path Variable ID_                               |
| **GET**    | `/api/pomodoros/stats/{uid}`     | Aggregated user statistics.               | _Path Variable UserID_                           |

## Architecture & Resilience

This project is not just code, it's engineering.

### Chaos Testing Results

The system has been subjected to the `chaos_test.sh` protocol:

- **Security:** ✅ Successful blocking of access attempts without a token (403 Forbidden).
- **Validation:** ✅ Rejection of corrupt or illogical data (e.g., negative times) with sanitized error messages (400 Bad Request).
- **Load:** ✅ Capable of processing **20 concurrent sessions in \<500ms** without service degradation.

## FAQ

**Q: Can I store the JWT in localStorage?**
A: No. If you want to gift your users' credentials to the first XSS script that comes along, go ahead. Here we optimize for security, which is why we use `HttpOnly` Cookies.

**Q: Why Spring Boot 4.0.0?**
A: Because living in the past is for historians. We use the latest in Java technology to ensure long-term compatibility and performance (and because it compiles and runs, which is what matters).

**Q: Is MongoDB Atlas really necessary?**
A: A man can dream of local databases. But to achieve physical layer separation and service independence, Atlas is the only truth (and the Free Tier is eternal).

**Q: Why Java and not Node.js/Python?**
A: Because when you need strict typing, real dependency injection, and a compiler that yells at you before breaking production, Java is king. Also, we like sleeping soundly knowing the Thread Pool will hold.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
