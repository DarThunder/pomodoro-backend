# Pomodoro API - Quick Start Guide

Hi\! If you're reading this, you're about to run the Pomodoro App backend on your machine. Here are the simple steps to get it up and running, whether you choose **Docker** (recommended/easy) or the **Old School** way (pure Java).

## Prerequisites

- **Git** (to clone this).
- **Docker Desktop** (if you choose the Easy Way).
- **Java 17 JDK** and **Maven** (only if you choose the Manual Way).

---

## Option A: The Easy Way (Docker)

This is the best option because you don't need to install Java or Mongo on your PC. Docker handles everything.

1.  **Open a terminal** in the project's root folder (where the `docker-compose.yml` file is).

2.  **Run the magic command:**

    ```bash
    docker-compose up --build
    ```

3.  **Done\!**

    - The backend will be running at: `http://localhost:8080`
    - The database (Mongo) will be at port `27017`.

_(To stop it, simply press `Ctrl + C` in the terminal)._

---

## Option B: The Manual Way (Java + Local Mongo)

Use this if you want to code or modify the Java source and don't want to rebuild the Docker image constantly.

1.  **Make sure MongoDB is running** locally on port `27017`.

2.  **Open a terminal** in the project folder.

3.  **Run the backend** using the included Maven wrapper (so you don't need to install Maven globally):

    - **On Windows:**

      ```cmd
      mvnw.cmd spring-boot:run
      ```

    - **On Mac/Linux:**

      ```bash
      ./mvnw spring-boot:run
      ```

---

## Connecting the Frontend

If you are using the `index.html` and `login.js` provided, make sure your `config.js` file in the frontend points to this backend:

```javascript
// In your frontend/config.js
const CONFIG = {
  API_URL: "http://localhost:8080/api",
};
```

**Note on CORS:**
By default, the backend accepts requests from `http://localhost:5500` (common Live Server port) or `http://localhost:3000`. If your frontend runs on a different port, you can change it in the `src/main/resources/application.properties` file or define a `FRONTEND_URL` environment variable.

---

## How do I know if it works?

The project includes some cool scripts to verify that everything is alive.

1.  With the server running, open another terminal (Git Bash or Linux/Mac).

2.  Go to the `scripts/` folder.

3.  Run the API test:

    ```bash
    ./test_api.sh
    ```

If you see a bunch of JSONs and finally `=== TEST COMPLETADO ===` (Test Completed), congratulations\! You have an "Enterprise Grade" backend running on your machine.

---

## Test Users

You can register a new one via Frontend or use the test script, but remember:

- **User:** (You create it when registering)
- **Pass:** (Whatever you choose)

_Data is saved in the Docker volume, so you won't lose your Pomodoros if you restart the container_.
