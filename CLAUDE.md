# Project Configuration

## Sub-agents
**IMPORTANT**: Use appropriate agent for each task (see `.claude/agents/`)
- **openapi**: API specs | **sql**: DB schema | **backend**: Express/Prisma
- **frontend**: Vue3/Vuetify | **test**: E2E | **prisma**: @map config
- **devops**: Docker/CI | **docs**: README | **acl**: permissions | **setup**: env config

## Stack
- **Core**: Node.js 22/Yarn 4/ESM/JS only (TS for devDeps)
- **Frontend**: Vue3+Vuetify3 SPA (JP i18n) port:5173
- **Backend**: Express REST API port:3000
- **DB**: MySQL 8.4, Redis (DB0:sessions, DB1:cache)
- **Libs**: config, luxon, nanoid(32), axios, js-cookie, bcrypt

## Conventions
- **Comments/tests**: Japanese | **Files**: kebab-case | **Commits**: English
- **ESLint Airbnb**: 
  - No await in loops → use Promise.all() or for...of
  - Prefer destructuring, const over let, semicolons required
  - Single quotes (except to avoid escaping)
  - Remove: unused vars, console.log, trailing spaces, var
  - Object shorthand: `{ method() {} }` not `{ method: function() {} }`
- **Avoid regex**: Prioritize readability

## API & DB
- **API**: `/api/v1/`, snake_case paths, camelCase data, UNIX timestamps (seconds), limit/offset
- **Auth**: Bearer token only (frontend: js-cookie)
- **Validation**: express-openapi-validator only (no manual validation)
- **DB**: Rails naming (plural tables, singular columns)
- **Prisma**: @map for snake_case→camelCase conversion
- **Views**: Complex joins as `v_` prefix views
- **Schema**: build-schema.sh (NO Prisma migrations)

## Structure
```
src/          # Frontend (Vue3/Vuetify3)
srv/          # Backend (Express/Prisma)
  routes/     # API routes (direct Prisma - YAGNI)
  lib/        # Shared utils (errors, acl, transformer)
  middleware/ # Auth, validation, permissions
tests/        # E2E tests (Node test runner + Supertest)
sql/          # Schema (build-schema.sh generates full)
openapi/      # API specs (split management)
```

## Commands
**Manual terminals**: 
- `yarn express` (backend:3000)
- `yarn serve` (frontend:5173)

**Claude Code OK**:
- `yarn build:openapi` - Bundle OpenAPI (REQUIRED before API testing)
- `yarn build:openapi:full` - With examples/descriptions (dev)
- `NODE_ENV=test yarn test:api` - Run E2E tests (auto DB config)
- `yarn prisma:seed` - Seed DB (see seed file for default password)
- `yarn prisma:sync` - Sync Prisma schema
- `ALLOW_DB_CLEAR=true yarn prisma:seed` - Reset and seed

**Production**: `NODE_ENV=production node srv/start.js` (serves both on :3000)

## Development Flow
1. Docker Compose → MySQL/Redis
2. `sql/build-schema.sh` → DB schema
3. OpenAPI spec → `yarn build:openapi`
4. REST API implementation
5. **E2E tests (mandatory)**:
   - Success: CRUD, pagination, filtering, sorting
   - Errors: 400 (validation), 401 (no auth), 403 (no permission), 404, 409
   - Auth: roles (admin/user/guest), token expiry, invalid tokens
   - Boundaries: max/min values, empty strings, null, special chars
6. Frontend UI

## Git Hooks (Auto-validation)
- ESLint/Prettier code quality
- kebab-case file naming
- Prohibit: .env files, CommonJS (except TS for devDeps)
- Warn: Vue Options API usage

## Critical Implementation

### Middleware Order (srv/app.js) - MUST FOLLOW
```javascript
1. express.json()              // Basic middleware
2. responseTransformer         // BEFORE routes!
3. /api/v1/health             // BEFORE validator
4. OpenAPI validator          // BEFORE routes! (validates requests)
5. /api/v1/* routes           // API routes (after validation)
6. express.static(dist)       // Production only
7. spaFallback               // MUST BE LAST
```

### Validation Strategy
- **OpenAPI**: Handles basic request validation (required fields, formats)
- **validator library**: For complex validations OpenAPI can't handle
  - Password strength: `validator.isStrongPassword()` 
  - Custom business rules as needed
- **IMPORTANT**: OpenAPI validator MUST be before API routes

### Field Naming
- **DB**: Store password field directly (NOT `passwordHash`)
- **Prisma**: Use @map for snake_case to camelCase conversion
- **Response**: Auto-excludes `password` via transformer
- **Dates**: `*At` → UNIX timestamp, `*On` → YYYY-MM-DD

### Common Issues
- Port conflict: `lsof -i :3000` → kill process
- OpenAPI errors: Run `yarn build:openapi` first
- Docker not running: Check containers
- Auth: Check seed files for default password
- Test DB: Auto-configured via `srv/lib/db.js` when NODE_ENV=test
- Validation: OpenAPI validator must be BEFORE route handlers

## ACL Implementation (CRITICAL)

### ACL Structure
```javascript
{
  administrator: boolean,  // true = all permissions
  services: {
    users: { create, read, update, delete, manage },
    groups: { create, read, update, delete },
    attendances: { create, read, update, delete, complete },
    elearnings: { create, read, update, delete, complete },
    surveys: { create, read, update, delete, respond, analyze },
    reports: { create, read, update, delete },
    projects: { create, read, update, delete },
    tasks: { create, read, update, delete }
  }
}
```

### Usage Pattern
```javascript
import { ACL } from '../lib/acl.js';

// Login: normalize permissions
const acl = new ACL(user.acl);
const token = await createSession({
  id: user.id,
  email: user.email,
  name: user.name,
  permissions: acl.data  // Normalized ACL
});

// Middleware: creates req.acl
export const authenticate = async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) throw new ApiError(401, ErrorCodes.UNAUTHORIZED);
  
  const sessionData = await redisClient.get(`session:${token}`);
  req.user = JSON.parse(sessionData);
  req.acl = new ACL(req.user.permissions);
  next();
};

// Routes: check permissions
if (!req.acl.can('users', 'manage')) {
  throw new ApiError(403, ErrorCodes.FORBIDDEN);
}
```

### Permission Middleware
- `requirePermission(scope)` - Check specific permission
- `requireServiceAccess(service)` - Check service access
- `requireAdmin()` - Admin only

### Admin Configuration
- Administrator permission: `{ administrator: true }`
- Admin accounts defined in seed data
- Default passwords in seed configuration

## Health Check
- Path: `/api/v1/health` (no OpenAPI validation)
- Checks: server, database, redis, redisCache
- Status: 200 (all OK) or 503 (any error)
- Register BEFORE OpenAPI validator

## Error Handling
```javascript
import { ApiError, ErrorCodes } from '../lib/errors.js';

// One-line throws (no req/res needed)
throw new ApiError(404, ErrorCodes.USER_NOT_FOUND, 'User not found');
throw new ApiError(401, ErrorCodes.UNAUTHORIZED, 'Invalid token');
throw new ApiError(403, ErrorCodes.FORBIDDEN, 'Access denied');
```

## Response Transformer
- Auto-converts dates: `createdAt` → UNIX, `createdOn` → YYYY-MM-DD
- Auto-excludes: `password` field
- Handles nested objects/arrays recursively
