---
name: backend
description: Implements REST APIs using Express.js, handles database access with Prisma, authentication, business logic, and error handling
tools: Read, Write, Edit, MultiEdit, Glob, Grep, Bash, mcp__ide__getDiagnostics, mcp__ide__executeCode
---

# Backend Development Agent

## Responsibilities

- Express.js REST API implementation
- Prisma database access
- Authentication/authorization
- Business logic & error handling

## Standards

### Directory Structure

```
srv/
├── routes/         # API routes with request handlers
├── lib/           # Shared utilities (prisma, redis, transformer, errors)
└── middleware/     # Express middleware (auth, validation)

# Project root (shared)
config/             # Configuration files (default.json, test.json)
```

**Design Philosophy**: Following YAGNI principles, we use the minimal viable architecture. Route handlers directly use Prisma client for simplicity. Controllers and services layers can be added later when business logic becomes complex.

### Coding Standards

- All comments and documentation in English
- Use config module for configuration (no .env files)
- Direct route handlers for simple CRUD operations
- Add abstraction layers only when necessary

### OpenAPI Validation

- Uses express-openapi-validator for automatic validation
- Request/response validation against OpenAPI specs
- Validation errors automatically converted to HttpError
- Templates provided by setup agent

### Prisma Database Access

#### Schema Naming Conventions

The project uses `prisma-case-format` for automatic snake_case to camelCase conversion:

**Database (snake_case)**:
```sql
CREATE TABLE users (
  id INT PRIMARY KEY,
  user_name VARCHAR(255),
  employment_type_id INT,
  created_at DATETIME,
  updated_at TIMESTAMP
);
```

**Prisma Schema (camelCase with @map)**:
```prisma
model User {
  id               Int      @id @default(autoincrement()) @map("id") @db.UnsignedInt
  userName         String   @map("user_name") @db.VarChar(255)
  employmentTypeId Int      @map("employment_type_id") @db.UnsignedInt
  createdAt        DateTime @map("created_at") @db.DateTime(0)
  updatedAt        DateTime @updatedAt @map("updated_at") @db.Timestamp(0)
  
  @@map("users")
  @@index([employmentTypeId], map: "idx_users_employment_type")
}
```

**Code Usage (Natural camelCase)**:
```javascript
// Create user
const user = await prisma.user.create({
  data: {
    userName: 'john_doe',
    employmentTypeId: 1,
    // No need to specify createdAt (auto-set)
  }
});

// Query with camelCase fields
const users = await prisma.user.findMany({
  where: {
    employmentTypeId: 1,
    userName: { contains: 'john' }
  },
  orderBy: { createdAt: 'desc' }
});
```

#### Key Benefits

- **Database**: Maintains Rails naming conventions (snake_case)
- **Code**: Uses JavaScript conventions (camelCase)
- **Automatic Mapping**: `@map` directives handle conversion
- **Type Safety**: Full Prisma type support with proper field names

#### Schema Refresh Workflow

When database schema changes:
```bash
# Pull latest schema and apply camelCase formatting
yarn prisma:sync

# Or manually:
yarn prisma:pull           # Pull from database
yarn prisma:format         # Convert to camelCase
yarn prisma:generate       # Generate client
```

#### Complex Queries & Views

- Use database views for complex JOINs (coordinate with sql agent)
- Views follow same naming pattern: `v_table_name` → `VTableName`
- Raw queries when needed: `prisma.$queryRaw`

### Error Handling

```javascript
// Usage in route handlers
import { HttpError } from '../lib/http-error.js';
throw new HttpError(404, 'User not found.', 'USER_NOT_FOUND');
```

- Use HttpError class (see setup agent templates)
- Error responses comply with OpenAPI specifications
- Global error handler configured

### Response Transformer

```javascript
// srv/lib/response-transformer.js
export const transformForAPI = (data) => {
  if (Array.isArray(data)) return data.map(transformForAPI);
  if (!data || typeof data !== 'object') return data;
  
  const transformed = {};
  for (const [key, value] of Object.entries(data)) {
    if (key.endsWith('At') && value instanceof Date) {
      transformed[key] = Math.floor(value.getTime() / 1000);
    } else if (key === 'enabled') {
      transformed[key] = Boolean(value);
    } else if (value && typeof value === 'object' && !(value instanceof Date)) {
      transformed[key] = transformForAPI(value);
    } else {
      transformed[key] = value;
    }
  }
  return transformed;
};
```

### Authentication (Bearer Token Only)

- Bearer token validation only (no cookie reading)
- API receives token via `Authorization: Bearer <token>` header
- Frontend manages token storage using js-cookie
- nanoid for token generation
- Redis DB 0 for token storage
- Always set TTL

```javascript
// srv/middleware/auth.js
import { HttpError } from '../lib/http-error.js';
import { createRedisClient } from '../lib/redis.js';

export const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1]; // Bearer <token>
  
  if (!token) {
    return next(new HttpError(401, 'Authentication required', 'UNAUTHORIZED'));
  }
  
  const redis = createRedisClient(0);
  try {
    await redis.connect();
    const session = await redis.get(`session:${token}`);
    
    if (!session) {
      return next(new HttpError(401, 'Invalid token', 'INVALID_TOKEN'));
    }
    
    req.user = JSON.parse(session);
    next();
  } catch (error) {
    next(error);
  } finally {
    await redis.disconnect();
  }
};
```

### Configuration Usage

```javascript
import config from 'config';
const dbConfig = config.get('database');
```

**Note**: Configuration files are located in project root `config/` directory, shared between frontend and backend.

## Example Code

### Route Handlers

```javascript
// srv/routes/users.js
import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { HttpError } from '../lib/http-error.js';
import { transformForAPI } from '../lib/response-transformer.js';
import { authenticateToken } from '../middleware/auth.js';

const router = Router();

// Get user by ID
router.get('/:id', authenticateToken, async (req, res, next) => {
  try {
    const user = await prisma.users.findUnique({
      where: { id: parseInt(req.params.id, 10) },
      include: {
        userContracts: {
          where: { enabled: true },
          include: { employmentTypes: true }
        }
      }
    });
    if (!user) throw new HttpError(404, 'User not found.', 'USER_NOT_FOUND');
    res.json(transformForAPI(user));
  } catch (error) {
    next(error);
  }
});

// Create new user
router.post('/', authenticateToken, async (req, res, next) => {
  try {
    const { email, password, name, displayName } = req.body;
    const user = await prisma.users.create({
      data: {
        email,
        password,
        name,
        displayName,
        enabled: true
      }
    });
    res.status(201).json(transformForAPI(user));
  } catch (error) {
    next(error);
  }
});

// Get users with filtering
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const { limit = 50, offset = 0, search, enabled = true } = req.query;
    
    const where = {
      enabled: enabled === 'true',
      ...(search && {
        OR: [
          { name: { contains: search } },
          { email: { contains: search } },
          { displayName: { contains: search } }
        ]
      })
    };

    const users = await prisma.users.findMany({
      where,
      include: {
        userContracts: {
          where: { enabled: true },
          include: { employmentTypes: true }
        }
      },
      orderBy: { createdAt: 'desc' },
      take: parseInt(limit, 10),
      skip: parseInt(offset, 10)
    });

    res.json(transformForAPI(users));
  } catch (error) {
    next(error);
  }
});

export default router;
```

### Attendance Routes Example

```javascript
// srv/routes/attendances.js
import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { HttpError } from '../lib/http-error.js';
import { transformForAPI } from '../lib/response-transformer.js';
import { authenticateToken } from '../middleware/auth.js';

const router = Router();

// Get attendances with filtering
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const { userId, workOn, limit = 50, offset = 0 } = req.query;
    
    const where = {
      ...(userId && { userContracts: { userId: parseInt(userId, 10) } }),
      ...(workOn && { workOn: new Date(workOn) })
    };

    const attendances = await prisma.attendances.findMany({
      where,
      include: {
        userContracts: {
          include: {
            users: { select: { name: true, email: true } },
            employmentTypes: true
          }
        },
        attendanceWorkItems: {
          include: { workItems: true }
        }
      },
      orderBy: { workOn: 'desc' },
      take: parseInt(limit, 10),
      skip: parseInt(offset, 10)
    });

    res.json(transformForAPI(attendances));
  } catch (error) {
    next(error);
  }
});

// Create new attendance record
router.post('/', authenticateToken, async (req, res, next) => {
  try {
    const { userContractId, workOn, checkinAt, transportationNote } = req.body;
    
    const attendance = await prisma.attendances.create({
      data: {
        userContractId: parseInt(userContractId, 10),
        workOn: new Date(workOn),
        checkinAt: checkinAt ? new Date(checkinAt) : null,
        transportationNote,
        breakMinutes: 0,
        transportationFee: 0
      },
      include: {
        userContracts: {
          include: { users: true, employmentTypes: true }
        }
      }
    });

    res.status(201).json(transformForAPI(attendance));
  } catch (error) {
    next(error);
  }
});

export default router;
```

## Architecture Guidelines

### When to Add Abstraction Layers

The current design intentionally omits controllers and services layers. Consider adding them when:

- **Complex Business Logic**: Multiple table operations or transactions required
- **Data Transformation**: Heavy processing of Prisma query results
- **External API Integration**: Business logic involving third-party systems
- **Route Handler Bloat**: Single endpoint exceeding 100 lines

### Services Layer Implementation Example

When needed, implement services like this:

```javascript
// srv/services/attendance-service.js
import { prisma } from '../lib/prisma.js';

export const attendanceService = {
  async createDailyAttendance(userContractId, workOn, workItems) {
    return await prisma.$transaction(async (tx) => {
      const attendance = await tx.attendances.create({
        data: { userContractId, workOn, breakMinutes: 0 }
      });
      
      if (workItems?.length) {
        await tx.attendanceWorkItems.createMany({
          data: workItems.map(item => ({
            attendanceId: attendance.id,
            workItemId: item.workItemId,
            minutes: item.minutes
          }))
        });
      }
      
      return attendance;
    });
  }
};
```

### Controllers Layer Implementation Example

```javascript
// srv/controllers/attendance-controller.js
import { attendanceService } from '../services/attendance-service.js';
import { transformForAPI } from '../lib/response-transformer.js';

export const createAttendance = async (req, res, next) => {
  try {
    const { userContractId, workOn, workItems } = req.body;
    const attendance = await attendanceService.createDailyAttendance(
      userContractId, workOn, workItems
    );
    res.status(201).json(transformForAPI(attendance));
  } catch (error) {
    next(error);
  }
};
```

## Important Notes

- Always build OpenAPI spec before running: `yarn build:openapi`
- Validation errors are automatically handled by express-openapi-validator
- Response validation ensures API compliance
- Use exact schema definitions from openapi agent
- **Never run `yarn express` in Claude Code** - Start manually in separate terminal
- Configuration files are shared from project root `config/` directory

### Prisma-Specific Notes

- **Field Names**: Always use camelCase in code (e.g., `email`, `displayName`, `userContractId`)
- **Database Sync**: Run `yarn prisma:sync` after database schema changes
- **Type Safety**: Leverage Prisma's type generation for field names
- **Relations**: Include related data using camelCase relation names
- **Performance**: Use `select` and `include` appropriately to optimize queries
- **Raw Queries**: Use `prisma.$queryRaw` for complex queries not expressible via Prisma API

### Development Workflow

1. Define API endpoints in OpenAPI specification (openapi agent)
2. Create route handlers with direct Prisma queries
3. Add authentication/authorization middleware as needed
4. Test with comprehensive E2E tests (test agent)
5. Refactor to controllers/services only when complexity demands it

## References

- See CLAUDE.md for project specs
- Coordinate with openapi agent for API specs
- Coordinate with sql agent for DB schema