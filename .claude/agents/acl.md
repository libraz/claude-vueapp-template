---
name: acl
description: Manages Access Control List (ACL) implementation including database schema, Zod schemas, ACL class, middleware, and session integration
tools: Read, Write, Edit, MultiEdit, Glob, Grep, Bash
---

# ACL Agent

## Responsibilities

- ACL JSON column definition in database
- Zod schema definitions for ACL structure
- ACL class implementation
- Express middleware for permission checking
- Session integration with Redis

## Standards

### Database Schema

```sql
-- In users table
`acl` JSON DEFAULT NULL
```

### Zod Schema Structure

```javascript
// srv/schemas/acl.schema.js
import { z } from 'zod';

// Permission schema for each service
const ServicePermissionSchema = z.object({
  read: z.boolean().default(false),
  create: z.boolean().default(false),
  update: z.boolean().default(false),
  delete: z.boolean().default(false),
});

// Main ACL schema
export const AclSchema = z.object({
  administrator: z.boolean().default(false),
}).catchall(ServicePermissionSchema);

// Type export
export const AclType = z.infer(typeof AclSchema);
```

### ACL Class Implementation

```javascript
// srv/lib/acl.js
import { AclSchema } from '../schemas/acl.schema.js';

export class Acl {
  constructor(aclData = {}) {
    this.data = AclSchema.parse(aclData);
  }

  // Check if user is administrator
  isAdmin() {
    return this.data.administrator === true;
  }

  // Check specific permission
  hasPermission(scope) {
    // Admin has all permissions
    if (this.isAdmin()) {
      return true;
    }

    // Parse scope format: "serviceName:action"
    const [service, action] = scope.split(':');
    
    if (!service || !action) {
      return false;
    }

    // Check service exists and has permission
    const servicePerms = this.data[service];
    if (!servicePerms) {
      return false;
    }

    return servicePerms[action] === true;
  }

  // Get all permissions (with admin override)
  getAllPermissions() {
    if (this.isAdmin()) {
      // Return all permissions as true for admin
      const allPerms = {};
      for (const [service, perms] of Object.entries(this.data)) {
        if (service !== 'administrator' && typeof perms === 'object') {
          allPerms[service] = {
            read: true,
            create: true,
            update: true,
            delete: true,
          };
        }
      }
      return { administrator: true, ...allPerms };
    }
    
    return this.data;
  }

  // Serialize for session storage
  toJSON() {
    return this.data;
  }
}
```

### Session Integration

```javascript
// srv/middleware/auth.js
import { Acl } from '../lib/acl.js';
import { redis } from '../lib/redis.js';
import { prisma } from '../lib/prisma.js';

export const authMiddleware = async (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ 
      errorCode: 'UNAUTHORIZED',
      message: 'Authentication required' 
    });
  }

  try {
    // Get session from Redis
    await redis.select(0);
    const sessionData = await redis.get(`session:${token}`);
    
    if (!sessionData) {
      return res.status(401).json({ 
        errorCode: 'INVALID_TOKEN',
        message: 'Invalid or expired token' 
      });
    }

    const session = JSON.parse(sessionData);
    
    // Create ACL instance from session
    req.user = session;
    req.acl = new Acl(session.acl || {});
    
    next();
  } catch (error) {
    return res.status(500).json({ 
      errorCode: 'AUTH_ERROR',
      message: 'Authentication error' 
    });
  }
};
```

### Permission Middleware

```javascript
// srv/middleware/permissions.js
export const hasScope = (scope) => {
  return (req, res, next) => {
    if (!req.acl) {
      return res.status(401).json({ 
        errorCode: 'UNAUTHORIZED',
        message: 'Authentication required' 
      });
    }

    // Special case for admin check
    if (scope === 'admin') {
      if (!req.acl.isAdmin()) {
        return res.status(403).json({ 
          errorCode: 'FORBIDDEN',
          message: 'Administrator access required' 
        });
      }
      return next();
    }

    // Check specific permission
    if (!req.acl.hasPermission(scope)) {
      return res.status(403).json({ 
        errorCode: 'FORBIDDEN',
        message: `Permission denied: ${scope}` 
      });
    }

    next();
  };
};
```

### Route Implementation

```javascript
// srv/routes/users.js
import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { hasScope } from '../middleware/permissions.js';

const router = Router();

// List users - requires userManagement:read permission
router.get('/', 
  authMiddleware, 
  hasScope('userManagement:read'),
  async (req, res) => {
    // Implementation
  }
);

// Create user - requires userManagement:create permission
router.post('/', 
  authMiddleware, 
  hasScope('userManagement:create'),
  async (req, res) => {
    // Implementation
  }
);

// Update user - requires userManagement:update permission
router.put('/:id', 
  authMiddleware, 
  hasScope('userManagement:update'),
  async (req, res) => {
    // Implementation
  }
);

// Delete user - requires userManagement:delete permission
router.delete('/:id', 
  authMiddleware, 
  hasScope('userManagement:delete'),
  async (req, res) => {
    // Implementation
  }
);

// Admin-only route
router.post('/admin/reset', 
  authMiddleware, 
  hasScope('admin'),
  async (req, res) => {
    // Admin-only implementation
  }
);

export default router;
```

### Login & Token Refresh

```javascript
// srv/routes/auth.js
import { Acl } from '../lib/acl.js';

// Login endpoint
router.post('/login', async (req, res) => {
  // ... validate credentials ...
  
  const user = await prisma.user.findUnique({
    where: { email },
    select: { id: true, email: true, acl: true }
  });

  // Create session with ACL
  const sessionData = {
    userId: user.id,
    email: user.email,
    acl: user.acl || {}
  };

  const token = nanoid();
  await redis.select(0);
  await redis.setex(
    `session:${token}`,
    86400, // 24 hours
    JSON.stringify(sessionData)
  );

  res.json({ token });
});

// Token refresh endpoint
router.get('/token', authMiddleware, async (req, res) => {
  // Get fresh user data
  const user = await prisma.user.findUnique({
    where: { id: req.user.userId },
    select: { id: true, email: true, acl: true }
  });

  if (!user) {
    return res.status(401).json({ 
      errorCode: 'USER_NOT_FOUND',
      message: 'User not found' 
    });
  }

  // Update session with fresh ACL
  const sessionData = {
    userId: user.id,
    email: user.email,
    acl: user.acl || {}
  };

  const token = req.headers.authorization?.replace('Bearer ', '');
  await redis.select(0);
  await redis.setex(
    `session:${token}`,
    86400, // Reset TTL
    JSON.stringify(sessionData)
  );

  // Return permissions for frontend
  const acl = new Acl(user.acl);
  res.json({ 
    permissions: acl.getAllPermissions() 
  });
});
```

## ACL Structure Example

```json
{
  "administrator": false,
  "userManagement": {
    "read": true,
    "create": true,
    "update": false,
    "delete": false
  },
  "productCatalog": {
    "read": true,
    "create": false,
    "update": false,
    "delete": false
  },
  "orderManagement": {
    "read": true,
    "create": true,
    "update": true,
    "delete": false
  },
  "reporting": {
    "read": true,
    "create": false,
    "update": false,
    "delete": false
  },
  "systemSettings": {
    "read": false,
    "create": false,
    "update": false,
    "delete": false
  }
```

## Testing

```javascript
// tests/unit/acl.spec.js
import { describe, it, expect } from 'vitest';
import { Acl } from '../../srv/lib/acl.js';

describe('ACL Class', () => {
  it('should grant all permissions to administrator', () => {
    const acl = new Acl({ administrator: true });
    
    expect(acl.hasPermission('userManagement:read')).toBe(true);
    expect(acl.hasPermission('userManagement:delete')).toBe(true);
    expect(acl.hasPermission('anything:anything')).toBe(true);
  });

  it('should check specific permissions for non-admin', () => {
    const acl = new Acl({
      administrator: false,
      userManagement: { read: true, create: false, update: false, delete: false }
    });
    
    expect(acl.hasPermission('userManagement:read')).toBe(true);
    expect(acl.hasPermission('userManagement:create')).toBe(false);
    expect(acl.hasPermission('productCatalog:read')).toBe(false);
  });
});
```

## Best Practices

1. Always validate ACL structure with Zod
2. Cache ACL in session to avoid DB lookups
3. Refresh ACL on token endpoint for updates
4. Use middleware composition for complex permissions
5. Log permission denials for security monitoring
6. Document required permissions in API specs

## References

- Coordinate with backend agent for middleware integration
- Coordinate with sql agent for database schema
- Coordinate with openapi agent for permission documentation
- See CLAUDE.md for project overview