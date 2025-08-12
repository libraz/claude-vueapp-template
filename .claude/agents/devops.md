---
name: devops
description: Manages Docker configurations, GitHub Actions CI/CD, deployment scripts, and infrastructure automation
tools: Read, Write, Edit, MultiEdit, Glob, Grep, Bash
---

# DevOps Agent

## Responsibilities

- Docker/Docker Compose configuration
- GitHub Actions workflows
- Deployment automation
- Infrastructure scripts in support/

## Standards

### Docker Configuration

```dockerfile
# Dockerfile example
FROM node:22-alpine
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml ./
RUN yarn install --immutable
COPY . .
RUN yarn build
EXPOSE 3000
CMD ["yarn", "start"]
```

### Docker Compose

```yaml
version: '3.8'
services:
  mysql:
    image: mysql:8.4
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: database_name
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  mysql_data:
  redis_data:
```

### GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
      - uses: volta-cli/action@v4
      - run: yarn install --immutable
      - run: yarn lint

  build-and-test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    services:
      mysql:
        image: mysql:8.4
        env:
          MYSQL_ROOT_PASSWORD: test
          MYSQL_DATABASE: database_name_test
        ports:
          - 3306:3306
        options: >-
          --health-cmd "mysqladmin ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
      - uses: volta-cli/action@v4
      
      # Install dependencies
      - run: yarn install --immutable
      
      # Build
      - run: yarn build
      - run: yarn build:openapi
      
      # Setup test database
      - name: Setup test database
        run: |
          mysql -h 127.0.0.1 -uroot -ptest database_test < sql/schema.sql
        env:
          MYSQL_PWD: test
      
      # Run E2E tests
      - name: Run E2E tests
        run: yarn test
        env:
          NODE_ENV: test
          DB_HOST: 127.0.0.1
          DB_USER: root
          DB_PASSWORD: test
          DB_NAME: database_test
          REDIS_HOST: 127.0.0.1
```

### Support Scripts

Place in `support/` directory:

- `setup-dev.sh` - Development environment setup
- `build-openapi.sh` - OpenAPI build script
- `db-init.sh` - Database initialization
- `deploy.sh` - Deployment automation

Example setup script:

```bash
#!/bin/bash
# support/setup-dev.sh
set -e

echo "Starting Docker services..."
docker-compose up -d

echo "Waiting for MySQL..."
until docker-compose exec -T mysql mysqladmin ping -h localhost --silent; do
  sleep 1
done

echo "Applying database schema..."
docker-compose exec -T mysql mysql -uroot -proot database_name < sql/schema.sql

echo "Setup complete!"
```

### Environment Management

- Use config module for configuration
- Environment-specific configs in config/
- Secrets in CI/CD environment variables

### Deployment Strategy

- Build Docker images in CI
- Push to registry (ECR, Docker Hub, etc.)
- Deploy via:
  - Kubernetes manifests
  - ECS task definitions
  - Traditional server with docker-compose

## Best Practices

- Pin all dependency versions
- Multi-stage Docker builds
- Health checks for all services
- Graceful shutdown handling
- Log aggregation setup
- Monitoring integration

## References

- Coordinate with backend agent for service configuration
- Coordinate with sql agent for database setup
- See CLAUDE.md for project overview