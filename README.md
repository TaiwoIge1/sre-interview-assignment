# Instructions for Running and Testing the Solution

## Running the Application Locally

### Prerequisites:
- Docker and Docker Compose installed.
- Node.js (v22.14.0 recommended) for local development without Docker.
- Git to clone the repository.

### Clone the Repository:
```bash
git clone <your-private-fork-url>
cd <repository-directory>
```

### Using Docker Compose:
The docker-compose.yml sets up a Postgres database and the API service.

Run the application in development mode:
```bash
docker-compose up --build
```

This builds the API image with `NODE_ENV=development` and maps port 3000 for the API and 5432 for Postgres.

The API will be accessible at http://localhost:3000.

The Postgres database uses the credentials:
- POSTGRES_USER=swapi
- POSTGRES_PASSWORD=password
- POSTGRES_DB=swapi

---

## Running Tests Locally

### With Docker:
```bash
docker build --target tester -t test-image:latest .
docker run --rm -e DATABASE_URL=postgres://swapi:password@localhost:5432/swapi test-image:latest
```
(Note: Ensure Postgres is running via `docker-compose up` or a local Postgres instance.)

### Without Docker:
```bash
npm install
npm run test
```

For continuous testing during development:
```bash
npm run test:watch
```

For test coverage:
```bash
npm run test:coverage
```

---

## Accessing the Application

The API exposes endpoints like `/species`, `/species/:id`, and `/planets/:id/destruction` as tested in `api.integration.test.ts`.

Example:
```bash
curl http://localhost:3000/species
```
to retrieve species data.

---

## Testing the CI Pipeline

The CI pipeline is defined in `.github/workflows/ci.yml`.

- It runs automatically on every push to any branch and on pull requests.
- Test results are output in JUnit format (`junit.xml`) and uploaded as artifacts in GitHub Actions for visibility in PRs.
- On pushes to the `main` branch, a production image is built and pushed to `ttl.sh/floatschedule-sre-assignment:<commit-sha>`.

---

## Verifying the Container Registry

After a successful push to main, the production image is available at:
```
ttl.sh/floatschedule-sre-assignment:<commit-sha>
```

You can pull and run the image:
```bash
docker pull ttl.sh/floatschedule-sre-assignment:<commit-sha>
docker run -p 3000:3000 -e DATABASE_URL=postgres://swapi:password@<postgres-host>:5432/swapi ttl.sh/floatschedule-sre-assignment:<commit-sha>
```

---

## Notes on Additional Features

### Enhanced Test Reporting:
- Integrate a GitHub Action to post test coverage reports as PR comments using tools like **codecov** or **coveralls**.
- Add visual test result dashboards (e.g., using **Allure reports**) for better developer feedback.

### Security Improvements:
- Add a `docker-compose.prod.yml` for production-like local testing with minimal dependencies and locked-down permissions.
- Implement image scanning in the CI pipeline (e.g., using **Trivy**) to detect vulnerabilities in dependencies or the base image.

### CI Optimizations:
- Use multi-stage caching more aggressively to speed up builds by separating dependency installation and code copying.
- Parallelize test execution across multiple runners to reduce CI runtime for larger test suites.

### Monitoring and Logging:
- Add health check endpoints to the API and configure them in the Dockerfile (`HEALTHCHECK` instruction).
- Integrate structured logging (e.g., using **pino**) and expose logs to a centralized system for debugging CI failures.

### Environment Flexibility:
- Parameterize the container registry URL and image tags via GitHub Actions secrets or environment variables for reusability across projects.
- Add support for multiple database backends (e.g., MySQL as an alternative to Postgres) to make the pipeline more reusable.
