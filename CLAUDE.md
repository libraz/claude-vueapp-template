# Project Configuration

## Sub-agent Configuration

Development is divided among the following sub-agents:

- **setup**: Environment setup, configuration file management
- **openapi**: OpenAPI specification creation and management
- **sql**: Database schema and view management
- **backend**: Server-side development (Express, Prisma)
- **frontend**: Frontend development (Vue3, Vuetify)
- **test**: E2E test creation
- **prisma**: Prisma schema management, @map configuration
- **devops**: Docker, GitHub Actions, deployment
- **docs**: Documentation management (README, docs/)
- **acl**: Access control list, permission management, middleware

See individual agent files in `.claude/agents/` for details.

## Project Overview

- Node.js 22.x monorepo web application
- Frontend: Vue3 + Vuetify3 SPA (with Japanese localization)
- Backend: Express REST API

## Technology Stack

### Base Environment

- Node.js 22.x (managed by Volta)
- Yarn 4.x (fixed to `node-modules` in `.yarnrc.yml`)
- ESM (type: module)
- JavaScript (no TypeScript, auto-validated by Git hooks)

### Main Libraries

- **Configuration**: config (.env file usage auto-validated by Git hooks)
- **Date/Time**: luxon
- **ID Generation**: nanoid
- **HTTP Client**: axios
- **Cookies**: js-cookie

### Data Stores

- MySQL 8.4.x
- Redis (DB0: sessions, DB1: cache)
- Docker Compose

## Common Conventions

### Coding

- Comments/test names: Japanese
- Source code: JSDoc format comments
- File names: kebab-case (auto-validated by Git hooks)
- ESLint/Prettier: auto-validated by Git hooks

### API

- Base path: `/api/v1/`
- Paths: snake_case
- Data: camelCase
- Errors: English
- Dates: UNIX timestamp (seconds)
- Pagination: `limit`/`offset`
- Authentication: Bearer token only (frontend manages with js-cookie)

### Database

- Naming: Rails convention (plural tables, singular columns)
- Use @map in Prisma (snake_case→camelCase)
- Complex joins defined as views (`v_` prefix)
- Cumulative management in schema.sql (Prisma migrations prohibited)

## Directory Structure

```text
/
├── .claude/agents/   # Sub-agent definitions
├── src/             # Frontend
├── srv/             # Backend
├── tests/           # E2E tests
├── sql/             # Schema (schema.sql)
├── openapi/         # API specifications (split management)
├── support/         # Helper scripts
└── docker-compose.yml
```

## Development Commands

```bash
# Run manually in separate terminals (not within Claude Code)
yarn express        # Start backend
yarn serve          # Start frontend

# Can run within Claude Code
yarn build          # Build
yarn build:openapi  # Bundle OpenAPI
yarn test           # Run tests
```

## Development Flow

1. Start MySQL/Redis with Docker Compose
2. Create DB schema (schema.sql)
3. Create OpenAPI specification
4. Implement REST API
5. **Comprehensive E2E test verification (mandatory)**
6. Create UI

### API Implementation Test Requirements

All API endpoints must have the following E2E tests upon implementation:

**Important**: Always run tests after creation and confirm they pass

- **Success Cases**
  - Success cases for each HTTP method (GET/POST/PUT/DELETE)
  - Pagination, filtering, sorting
  - Response format validation

- **Error Cases**
  - 400 Bad Request (validation errors)
  - 401 Unauthorized (no authentication)
  - 403 Forbidden (insufficient permissions)
  - 404 Not Found (resource not found)
  - 409 Conflict (duplicate errors, etc.)

- **Authentication/Authorization Tests**
  - Role-based access (admin/user/guest)
  - Token expiration
  - Invalid tokens

- **Boundary Value Tests**
  - Maximum/minimum values
  - Empty strings, null values
  - Special characters

---

See individual agent files for detailed specifications.

## Automatic Validation with Git Hooks

The following conventions are automatically validated by Git hooks:

- Code quality checks with ESLint/Prettier
- kebab-case validation for file names
- Prohibition of .env files, TypeScript, CommonJS
- Warning for Vue Options API usage
