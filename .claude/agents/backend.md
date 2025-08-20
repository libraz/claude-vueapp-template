---
name: backend
description: Express REST APIs, Prisma DB, auth, business logic
tools: Read, Write, Edit, MultiEdit, Glob, Grep, Bash, mcp__ide__getDiagnostics, mcp__ide__executeCode
---

# Backend Agent

**CRITICAL**: Never modify OpenAPI specs - use openapi agent

## Architecture
```
srv/
├── routes/     # API routes (direct Prisma - YAGNI)
├── lib/        # Shared utilities
│   ├── errors.js      # ApiError class, ErrorCodes
│   ├── acl.js         # ACL class for permissions
│   ├── transformer.js # Response transformation
│   └── resources.js   # DB, Redis clients
└── middleware/ # Express middleware
    ├── auth.js        # authenticate, requirePermission
    └── validator.js   # OpenAPI validation
```

## Middleware Order (CRITICAL)
```javascript
// srv/app.js - MUST FOLLOW THIS ORDER
app.use(express.json());                    // 1. Basic
app.use(responseTransformer);                // 2. Transform (BEFORE routes!)
app.use('/api/v1/health', healthRoutes);    // 3. Health (BEFORE validator)
app.use(OpenApiValidator.middleware({       // 4. OpenAPI validator (BEFORE routes!)
  apiSpec: 'srv/openapi/dist/openapi.yaml',
  validateRequests: true
}));
app.use('/api/v1/auth', authRoutes);        // 5. API routes (AFTER validator)
app.use('/api/v1/users', userRoutes);       
app.use(express.static(dist));              // 6. Static (production)
app.use(spaFallback);                       // 7. SPA fallback (LAST!)
```

**IMPORTANT**: OpenAPI validator MUST be before routes to validate requests
- No manual validation in route handlers
- OpenAPI handles all request validation

## Field Naming
- **Database**: `password` field (NOT `passwordHash`)
- **Prisma Model**: `Users` (plural, PascalCase)
- **Schema @map**: `createdAt DateTime @map("created_at")`
- **Code**: Natural camelCase via @map
- **Response**: Auto-excludes `password` via transformer

## Core Patterns

### Import Organization
```javascript
// lib/errors.js - Centralized exports
export class ApiError extends Error {
  constructor(statusCode, errorCode, message) { ... }
}
export const ErrorCodes = {
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  USER_NOT_FOUND: 'USER_NOT_FOUND',
  // ...
};

// routes/users.js - Clean imports
import { authenticate, requirePermission } from '../middleware/index.js';
import { ApiError, ErrorCodes } from '../lib/errors.js';
import { transformResponse } from '../lib/transformer.js';
```

### Error Handling
```javascript
// One-line throws (no req/res needed)
throw new ApiError(404, ErrorCodes.USER_NOT_FOUND, 'User not found');
throw new ApiError(401, ErrorCodes.UNAUTHORIZED, 'Invalid token');
throw new ApiError(403, ErrorCodes.FORBIDDEN, 'Access denied');
```

### Response Transformer
```javascript
// lib/transformer.js
export const transformResponse = (data, options = {}) => {
  // Fields ending with 'At' → UNIX timestamp (seconds)
  // Fields ending with 'On' → YYYY-MM-DD string
  // Excludes specified fields (e.g., password)
  // Handles nested objects/arrays recursively
};

// middleware/transformer.js
export const responseTransformer = (req, res, next) => {
  const originalJson = res.json;
  res.json = function(data) {
    const transformed = transformResponse(data, { exclude: ['password'] });
    return originalJson.call(this, transformed);
  };
  next();
};
```

### Prisma Schema
```javascript
model Users {
  id        Int      @id @default(autoincrement()) @map("id")
  email     String   @unique @map("email")
  password  String   @map("password")  // NOT passwordHash!
  name      String   @map("name")
  acl       Json     @map("acl")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")
  @@map("users")
}
```

## Route Implementation

### Basic CRUD Pattern
```javascript
// srv/routes/users.js
router.get('/:id', authenticate, async (req, res, next) => {
  try {
    const user = await prisma.users.findUnique({
      where: { id: parseInt(req.params.id, 10) },
      include: { userContracts: true }
    });
    
    if (!user) {
      throw new ApiError(404, ErrorCodes.USER_NOT_FOUND, 'User not found');
    }
    
    res.json(transformResponse(user, { exclude: ['password'] }));
  } catch (error) {
    next(error);
  }
});
```

### List with Filtering
```javascript
router.get('/', authenticate, async (req, res, next) => {
  try {
    const { limit = 50, offset = 0, search, departmentId } = req.query;
    
    const where = {};
    if (search) {
      where.OR = [
        { name: { contains: search } },
        { email: { contains: search } }
      ];
    }
    if (departmentId) {
      where.departmentId = parseInt(departmentId, 10);
    }
    
    const [users, total] = await Promise.all([
      prisma.users.findMany({
        where,
        take: parseInt(limit, 10),
        skip: parseInt(offset, 10),
        orderBy: { createdAt: 'desc' }
      }),
      prisma.users.count({ where })
    ]);
    
    res.json({
      data: transformResponse(users, { exclude: ['password'] }),
      meta: { total, limit, offset }
    });
  } catch (error) {
    next(error);
  }
});
```

## Validation & Security

### Password Validation
- **OpenAPI**: Basic format validation
- **validator.isStrongPassword()**: Enforces strength requirements
  - minLength: 8, minLowercase: 1, minUppercase: 1, minNumbers: 1
- Hashed with bcrypt (10 rounds)
- Check seed files for default passwords

### No Manual Validation
```javascript
// WRONG - Don't do manual validation
if (!email || !password) {
  throw new ApiError(400, ...);
}

// RIGHT - Let OpenAPI handle it
// Just use the validated values directly
const user = await prisma.users.findUnique({ where: { email } });
```

## ACL Implementation (REQUIRED)

### ACL Class Usage
```javascript
// lib/acl.js - Comprehensive permission system
import { ACL } from '../lib/acl.js';

// Login flow - normalize and store permissions
const user = await prisma.users.findUnique({ where: { email } });
const acl = new ACL(user.acl);  // Normalizes permissions

const token = nanoid(32);
await redisClient.setex(
  `session:${token}`,
  config.get('session.ttl'),
  JSON.stringify({
    id: user.id,
    email: user.email,
    name: user.name,
    permissions: acl.data  // Store normalized ACL
  })
);
```

### Authenticate Middleware
```javascript
// middleware/auth.js
export const authenticate = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      throw new ApiError(401, ErrorCodes.UNAUTHORIZED, 'Authentication required');
    }
    
    const sessionData = await redisClient.get(`session:${token}`);
    if (!sessionData) {
      throw new ApiError(401, ErrorCodes.UNAUTHORIZED, 'Invalid or expired token');
    }
    
    const userData = JSON.parse(sessionData);
    req.user = userData;
    req.acl = new ACL(userData.permissions);  // ACL instance available
    
    // Extend session TTL
    await redisClient.expire(`session:${token}`, config.get('session.ttl'));
    
    next();
  } catch (error) {
    next(error);
  }
};
```

### Permission Checking
```javascript
// Routes with permission checks
router.delete('/:id', authenticate, async (req, res, next) => {
  // Check permission
  if (!req.acl.can('users', 'delete')) {
    throw new ApiError(403, ErrorCodes.FORBIDDEN, 'Delete permission required');
  }
  
  // Proceed with deletion
  await prisma.users.delete({ where: { id } });
  res.status(204).send();
});

// Permission middleware helpers
export const requirePermission = (scope) => (req, res, next) => {
  if (!req.acl.hasPermission(scope)) {
    throw new ApiError(403, ErrorCodes.FORBIDDEN, `Permission '${scope}' required`);
  }
  next();
};

export const requireAdmin = () => (req, res, next) => {
  if (!req.acl.isAdministrator()) {
    throw new ApiError(403, ErrorCodes.FORBIDDEN, 'Administrator access required');
  }
  next();
};
```

## Health Check (Independent)

```javascript
// srv/routes/health.js - Outside OpenAPI validation
import { testDatabaseConnection } from '../lib/db.js';
import { redisClient, redisCacheClient } from '../lib/resources.js';

router.get('/', async (req, res) => {
  const checks = {
    status: 'ok',
    timestamp: Math.floor(Date.now() / 1000),
    environment: process.env.NODE_ENV || 'development'
  };

  // Check all services
  try {
    const dbConnected = await testDatabaseConnection();
    checks.database = dbConnected ? 'ok' : 'error';
  } catch { 
    checks.database = 'error';
  }

  try {
    await redisClient.ping();
    checks.redis = 'ok';
  } catch { 
    checks.redis = 'error';
  }

  try {
    await redisCacheClient.ping();
    checks.redisCache = 'ok';
  } catch { 
    checks.redisCache = 'error';
  }

  const hasError = Object.values(checks).includes('error');
  if (hasError) checks.status = 'error';
  
  res.status(hasError ? 503 : 200).json(checks);
});
```

## Service Layer (When Needed)

Current approach: Direct Prisma in routes (YAGNI principle)

Add service layer when:
- Complex transactions spanning multiple tables
- Business logic exceeds 100 lines
- External API integration required
- Shared logic across multiple routes

```javascript
// Example service layer (when complexity demands)
export const userService = {
  async createWithDefaults(data) {
    return prisma.$transaction(async (tx) => {
      const user = await tx.users.create({ data });
      await tx.userSettings.create({
        data: { userId: user.id, ...defaultSettings }
      });
      await tx.activityLogs.create({
        data: { userId: user.id, action: 'USER_CREATED' }
      });
      return user;
    });
  }
};
```

## Development Workflow

1. **OpenAPI first**: Define endpoints (openapi agent)
2. **Build spec**: `yarn build:openapi` (REQUIRED)
3. **Implement**: Direct Prisma in routes
4. **Test**: Comprehensive E2E tests (test agent)
5. **Refactor**: Add layers only when complexity demands

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Port conflict | `lsof -i :3000` then kill process |
| OpenAPI errors | Run `yarn build:openapi` first |
| Field mismatch | Use `password` not `passwordHash` |
| 404 on routes | Check middleware order |
| Auth fails | Check seed files for passwords |
| Docker | Ensure containers running |

## Quick Reference

**Commands**:
- `yarn build:openapi` - Build OpenAPI (REQUIRED before testing)
- `yarn express` - Start backend (manual terminal)
- `yarn prisma:sync` - Sync Prisma schema
- `yarn prisma:seed` - Seed database

**Config**: `config/default.json`
- Database URL, Redis settings
- Session TTL, JWT settings
- Shared with frontend

**Important**:
- **NEVER** modify `srv/openapi/` files directly
- Use appropriate agent for each task
- Default admin: `yumiko@harmilia.com`
- Check seed files for default passwords