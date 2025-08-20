---
name: setup
description: Handles project initial setup and boilerplate creation
tools: Read, Write, Edit, MultiEdit, Glob, Grep, Bash
---

# Setup Agent

Agent responsible for initial project setup and boilerplate creation

## Role

Creates initial directory structure, places configuration files, and generates boilerplate code.

## Responsibilities

### Directory Structure Creation

```bash
# Project root
├── .claude/agents/       # Agent definitions
├── config/              # Configuration files (default.json, etc.)
├── docs/                # Documentation
├── sql/                 # Database definitions
├── src/                 # Frontend
│   ├── assets/
│   ├── components/
│   ├── layouts/
│   ├── pages/
│   ├── plugins/
│   ├── router/
│   └── stores/
├── srv/                 # Backend
│   ├── lib/             # Shared utilities (prisma, redis, transformer, errors)
│   ├── middleware/      # Express middleware (auth, validation)
│   ├── openapi/         # OpenAPI specifications
│   │   └── components/  # Shared schemas
│   └── routes/          # API routes with handlers
├── support/             # Helper scripts
└── tests/               # Tests
    ├── api/             # API E2E tests (supertest)
    └── unit/            # Frontend unit tests
```

### Package Version Policy

#### ESLint Version Pinning

ESLint is pinned to version 8.x series to prevent compatibility issues with the current configuration:

```json
"eslint": "~8.57.1"
```

- **Reason**: ESLint 9.x introduces breaking changes that require configuration migration
- **Policy**: Use tilde (`~`) to allow patch updates within 8.x series
- **NCU Configuration**: Use `.ncurc.js` to prevent ESLint upgrades

**.ncurc.js**
```javascript
module.exports = {
  // ESLint 8系に固定（9系への自動アップデートを防止）
  reject: ['eslint']
};
```

#### Version Range Guidelines

- **Critical packages** (eslint, vue, express): Use tilde (`~`) for controlled updates
- **Standard packages**: Use caret (`^`) for minor updates
- **Utility packages**: Use caret (`^`) for flexibility

#### ESLint Plugin Configuration

Use dedicated plugins instead of manual global variable definitions:

- **eslint-plugin-vitest**: Automatic Vitest globals and testing rules
- **eslint-plugin-vue**: Vue 3 specific linting rules
- **Benefits**: Better rule validation, automatic global recognition, framework-specific best practices

### Initial Configuration File Placement

#### Code Format & Lint Configuration

- `.prettierrc` - Prettier format configuration (auto-validated by hooks)
- `.prettierignore` - Prettier exclusion settings
- `.eslintrc.js` - ESLint configuration (auto-validated by hooks)
- `.eslintignore` - ESLint exclusion settings
- `.markdownlint.json` - Markdown linting configuration (auto-validated by hooks)

#### Editor/IDE Configuration

- `.editorconfig` - Common editor settings
  ```ini
  root = true
  
  [*]
  charset = utf-8
  end_of_line = lf
  indent_style = tab
  indent_size = 2
  insert_final_newline = true
  trim_trailing_whitespace = true
  ```
- `.vscode/settings.json` - VSCode settings
  ```json
  {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": true
    },
    "eslint.validate": ["javascript", "vue"],
    "files.eol": "\n"
  }
  ```
- `.vscode/extensions.json` - Recommended extensions
  ```json
  {
    "recommendations": [
      "esbenp.prettier-vscode",
      "dbaeumer.vscode-eslint",
      "vue.volar",
      "editorconfig.editorconfig"
    ]
  }
  ```

#### Project Configuration

- `.gitignore` - Git exclusion settings
- `.dockerignore` - Docker exclusion settings
- `.yarnrc.yml` - Yarn configuration (nodeLinker: node-modules)
- `package.json` - Including Volta section (Node.js version pinning)
- `docker-compose.yml` - MySQL/Redis configuration
- `config/default.json` - Application configuration

**.gitignore**

```text
# Dependencies
node_modules/
.yarn/
.pnp.*

# Build outputs
dist/
build/
*.tsbuildinfo

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*
.pnpm-debug.log*

# Claude Code logs
.claude/command.log

# Environment files
.env
.env.*

# IDE
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Testing
coverage/
.nyc_output/

# Temporary files
tmp/
temp/
*.tmp
*.temp

# OpenAPI build
srv/openapi/dist/

# Database
*.sqlite
*.sqlite3

# Redis
dump.rdb
```

**.prettierrc**

```json
{
  "singleQuote": true,
  "semi": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf",
  "overrides": [
    {
      "files": "*.md",
      "options": {
        "proseWrap": "preserve"
      }
    }
  ]
}
```

**.markdownlint.json**

```json
{
  "default": true,
  "MD003": { "style": "atx" },
  "MD004": { "style": "dash" },
  "MD007": { "indent": 2 },
  "MD013": false,
  "MD024": { "siblings_only": true },
  "MD025": false,
  "MD033": false,
  "MD041": false,
  "line-length": false
}
```

### Boilerplate File Creation

#### Basic package.json Structure

```json
{
  "name": "project-name",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "engines": {
    "node": ">=22.0.0",
    "yarn": ">=4.0.0"
  },
  "volta": {
    "node": "22.12.0",
    "yarn": "4.5.3"
  },
  "scripts": {
    "dev": "concurrently \"yarn:express\" \"yarn:serve\"",
    "express": "nodemon srv/app.js",
    "serve": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext .js,.vue",
    "lint:fix": "eslint . --ext .js,.vue --fix",
    "format": "prettier --write \"**/*.{js,vue,json,md}\"",
    "format:check": "prettier --check \"**/*.{js,vue,json,md}\"",
    "test": "yarn test:api && yarn test:unit",
    "test:api": "vitest run tests/api",
    "test:unit": "vitest run tests/unit",
    "test:unit:ui": "vitest --ui",
    "build:openapi": "node support/openapi-builder.js",
    "validate:openapi": "node support/openapi-validator.js",
    "prisma:pull": "prisma db pull --force",
    "prisma:format": "prisma-case-format --file prisma/schema.prisma --table-case pascal --field-case camel --map-table-case snake,plural --map-field-case snake",
    "prisma:format:dry": "prisma-case-format --file prisma/schema.prisma --dry-run --table-case pascal --field-case camel --map-table-case snake,plural --map-field-case snake",
    "prisma:generate": "prisma generate",
    "prisma:sync": "yarn prisma:pull && yarn prisma:format && yarn prisma:generate",
    "ncu": "ncu",
    "ncu:minor": "ncu -u --target minor",
    "ncu:patch": "ncu -u --target patch",
    "ncu:all": "ncu -u"
  },
  "dependencies": {
    "@mdi/font": "^7.4.47",
    "@prisma/client": "^6.14.0",
    "axios": "^1.11.0",
    "bcrypt": "^5.1.1",
    "config": "^4.1.0",
    "express": "^5.1.0",
    "express-openapi-validator": "^5.5.8",
    "js-cookie": "^3.0.5",
    "js-yaml": "^4.1.0",
    "luxon": "^3.7.1",
    "nanoid": "^5.1.5",
    "pinia": "^3.0.3",
    "redis": "^5.8.1",
    "vue": "^3.5.18",
    "vue-router": "^4.5.1",
    "vuetify": "^3.9.5"
  },
  "devDependencies": {
    "@redocly/cli": "^2.0.5",
    "@vitejs/plugin-vue": "^6.0.1",
    "@vitest/ui": "^3.2.4",
    "@vue/test-utils": "^2.4.6",
    "concurrently": "^9.2.0",
    "eslint": "~8.57.1",
    "eslint-config-airbnb-base": "^15.0.0",
    "eslint-plugin-import": "^2.32.0",
    "eslint-plugin-vitest": "^0.5.4",
    "eslint-plugin-vue": "^9.28.0",
    "markdownlint-cli": "^0.45.0",
    "nodemon": "^3.1.10",
    "npm-check-updates": "^18.0.2",
    "prettier": "^3.6.2",
    "prisma": "^6.14.0",
    "prisma-case-format": "^2.2.1",
    "redoc-cli": "^0.13.21",
    "simple-git-hooks": "^2.13.1",
    "supertest": "^7.1.4",
    "typescript": "^5.9.2",
    "vite": "^7.1.2",
    "vitest": "^3.2.4"
  }
}
```

#### Backend Skeleton

**srv/app.js**

```javascript
import express from 'express';
import config from 'config';
import OpenApiValidator from 'express-openapi-validator';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { responseTransformer } from './lib/response-transformer.js';
import { testDatabaseConnection } from './lib/db.js';
import { prisma, redisClient, redisCacheClient } from './lib/resources.js';
import { displayRoutes, wrapAppUse } from './lib/route-inspector.js';

// API routes
import authRoutes from './routes/auth.js';
import userRoutes from './routes/users.js';
import healthRoutes from './routes/health.js';

// Import error response helper
import { ApiError, createErrorResponse, ErrorCodes } from './lib/errors.js';

// ES modules対応
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Initialize Express app
const app = express();

// Wrap app.use in development to capture route paths
wrapAppUse(app);

// Basic Middleware (ORDER IS CRITICAL - see CLAUDE.md)
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS設定 (開発環境用)
if (process.env.NODE_ENV === 'development') {
  app.use((req, res, next) => {
    /* eslint-disable consistent-return */
    res.header('Access-Control-Allow-Origin', 'http://localhost:5173');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.header('Access-Control-Allow-Credentials', 'true');
    if (req.method === 'OPTIONS') {
      return res.sendStatus(200);
    }
    return next();
    /* eslint-enable consistent-return */
  });
}

// Response transformer middleware
app.use(responseTransformer);

// Health check (OpenAPI管理外 - must be before validator)
app.use('/api/v1/health', healthRoutes);

// API Routes (OpenAPI-validated endpoints)
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);

// OpenAPI Validator (optional, after routes)
app.use(
  OpenApiValidator.middleware({
    apiSpec: join(__dirname, 'openapi', 'dist', 'openapi.yaml'),
    validateRequests: true,
    validateResponses: false,
    ajvFormats: true,
    ignoreUndocumented: true
  })
);

// Static file serving (production)
if (process.env.NODE_ENV === 'production') {
  app.use(express.static(join(__dirname, '..', 'dist')));
}

// SPA Fallback (production) - MUST BE LAST
if (process.env.NODE_ENV === 'production') {
  app.use((req, res, next) => {
    if (!req.path.startsWith('/api')) {
      res.sendFile(join(__dirname, '..', 'dist', 'index.html'));
    } else {
      next();
    }
  });
}

// Error handling middleware (must be after all routes)
app.use((err, req, res, next) => {
  // Handle ApiError instances
  if (err instanceof ApiError) {
    const errorResponse = createErrorResponse({
      statusCode: err.statusCode,
      errorCode: err.errorCode,
      message: err.message,
      path: req.originalUrl
    });
    return res.status(err.statusCode).json(errorResponse);
  }

  // OpenAPI validation error
  if (err.status && err.errors) {
    const errorResponse = createErrorResponse({
      statusCode: err.status,
      errorCode: ErrorCodes.VALIDATION_ERROR,
      message: 'Validation failed',
      path: req.originalUrl,
      errors: err.errors.map((error) => ({
        field: error.path || error.instancePath,
        errorCode: ErrorCodes.INVALID_FORMAT,
        message: error.message
      }))
    });
    return res.status(err.status).json(errorResponse);
  }

  // General error
  console.error('Error:', err);
  const errorResponse = createErrorResponse({
    statusCode: err.status || 500,
    errorCode: err.status === 500 ? ErrorCodes.INTERNAL_SERVER_ERROR : ErrorCodes.NOT_FOUND,
    message: err.message || 'Internal server error',
    path: req.originalUrl
  });
  return res.status(err.status || 500).json(errorResponse);
});

// Start server
const port = config.get('server.port');

// Test database connection before starting
testDatabaseConnection().then((isConnected) => {
  if (!isConnected) {
    console.error('Failed to connect to database. Please check your configuration.');
    process.exit(1);
  }

  app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    
    // Display routes in development
    displayRoutes(app);
  });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  await prisma.$disconnect();
  await redisClient.quit();
  await redisCacheClient.quit();
  process.exit(0);
});

export default app;
```

**srv/lib/errors.js**
```javascript
import { nanoid } from 'nanoid';

export const ErrorCodes = {
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  CONFLICT: 'CONFLICT',
  INTERNAL_SERVER_ERROR: 'INTERNAL_SERVER_ERROR',
  INVALID_CREDENTIALS: 'INVALID_CREDENTIALS',
  TOKEN_EXPIRED: 'TOKEN_EXPIRED',
  INVALID_TOKEN: 'INVALID_TOKEN',
  INVALID_FORMAT: 'INVALID_FORMAT',
  DUPLICATE_ENTRY: 'DUPLICATE_ENTRY',
  RESOURCE_NOT_FOUND: 'RESOURCE_NOT_FOUND',
  USER_NOT_FOUND: 'USER_NOT_FOUND',
  INSUFFICIENT_PERMISSIONS: 'INSUFFICIENT_PERMISSIONS'
};

export class ApiError extends Error {
  constructor(statusCode, errorCode, message, errors = null) {
    super(message);
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.errors = errors;
  }
}

export const createErrorResponse = ({ statusCode, errorCode, message, path, errors }) => ({
  statusCode,
  code: nanoid(12),
  errorCode,
  path,
  message,
  errors
});
```

**srv/lib/resources.js**
```javascript
import { PrismaClient } from '@prisma/client';
import { createClient } from 'redis';
import config from 'config';

// Prisma client
export const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' 
    ? ['query', 'info', 'warn', 'error']
    : ['warn', 'error']
});

// Redis clients
const redisConfig = config.get('redis');

// Session用Redis (DB0)
export const redisClient = createClient({
  url: `redis://${redisConfig.host}:${redisConfig.port}/0`
});

// Cache用Redis (DB1)
export const redisCacheClient = createClient({
  url: `redis://${redisConfig.host}:${redisConfig.port}/1`
});

// Connect Redis clients
redisClient.on('error', (err) => console.error('Redis Client Error:', err));
redisCacheClient.on('error', (err) => console.error('Redis Cache Error:', err));

await redisClient.connect();
await redisCacheClient.connect();
```

**srv/lib/db.js**
```javascript
import { prisma } from './resources.js';

export async function testDatabaseConnection() {
  try {
    await prisma.$queryRaw`SELECT 1`;
    console.log('Database connection successful');
    return true;
  } catch (error) {
    console.error('Database connection failed:', error);
    return false;
  }
}
```

**srv/lib/response-transformer.js**
```javascript
/*
Response data transformer for API outputs
*/

export const transformResponse = (data, options = {}) => {
  const { exclude = [] } = options;

  if (Array.isArray(data)) {
    return data.map((item) => transformResponse(item, options));
  }

  if (!data || typeof data !== 'object') return data;

  const result = { ...data };
  exclude.forEach((field) => delete result[field]);

  Object.keys(result).forEach((key) => {
    if (result[key] instanceof Date) {
      if (key.endsWith('At')) {
        // Timestamp fields (e.g., createdAt, updatedAt)
        result[key] = Math.floor(result[key].getTime() / 1000);
      } else if (key.endsWith('On')) {
        // Date fields (e.g., startedOn, endedOn)
        const year = result[key].getFullYear();
        const month = String(result[key].getMonth() + 1).padStart(2, '0');
        const day = String(result[key].getDate()).padStart(2, '0');
        result[key] = `${year}-${month}-${day}`;
      }
    }
  });

  Object.keys(result).forEach((key) => {
    if (result[key] && typeof result[key] === 'object' && !(result[key] instanceof Date)) {
      result[key] = transformResponse(result[key], options);
    }
  });

  return result;
};

// Export as responseTransformer middleware
export const responseTransformer = (_req, res, next) => {
  // Override the json method to apply transformation
  const originalJson = res.json.bind(res);
  res.json = function json(data) {
    // Apply transformation if data is an object
    if (data && typeof data === 'object') {
      const transformed = transformResponse(data, { exclude: ['password'] });
      return originalJson(transformed);
    }
    return originalJson(data);
  };
  next();
};
```

**srv/lib/route-inspector.js**
```javascript
import chalk from 'chalk';

// Route paths mapping
const routePaths = new Map();

export function wrapAppUse(app) {
  if (process.env.NODE_ENV !== 'development') return;
  
  const originalUse = app.use.bind(app);
  app.use = function useWrapper(...args) {
    if (args.length >= 2 && typeof args[0] === 'string' && typeof args[1] === 'function') {
      const [path, router] = args;
      if (router && router.stack) {
        routePaths.set(router, path);
      }
    }
    return originalUse(...args);
  };
}

export function displayRoutes(app) {
  if (process.env.NODE_ENV !== 'development') return;
  
  setTimeout(() => {
    const routes = [];
    
    function extractRoutes(stack, basePath = '') {
      if (!stack) return;
      
      stack.forEach((layer) => {
        if (layer.route) {
          const path = basePath + layer.route.path;
          const methods = Object.keys(layer.route.methods)
            .filter((method) => layer.route.methods[method])
            .map((method) => method.toUpperCase());
          routes.push({ path, methods });
        } else if (layer.name === 'router' && layer.handle && layer.handle.stack) {
          let newBasePath = basePath;
          if (routePaths.has(layer.handle)) {
            newBasePath = routePaths.get(layer.handle);
          }
          extractRoutes(layer.handle.stack, newBasePath);
        }
      });
    }
    
    const router = app.router || app._router;
    if (router && router.stack) {
      extractRoutes(router.stack);
    }
    
    // Group and display routes
    const groupedRoutes = {};
    routes.forEach(({ path, methods }) => {
      const cleanPath = path.replace(/\/+/g, '/').replace(/\/$/, '') || path;
      if (!groupedRoutes[cleanPath]) {
        groupedRoutes[cleanPath] = [];
      }
      groupedRoutes[cleanPath].push(...methods);
    });
    
    console.log('\n' + '━'.repeat(60));
    console.log('  API Endpoints');
    console.log('━'.repeat(60) + '\n');
    
    Object.keys(groupedRoutes).sort().forEach((path) => {
      const methods = [...new Set(groupedRoutes[path])].sort();
      console.log(`  ${path.padEnd(50)}${methods.join(', ')}`);
    });
    
    console.log('\n' + '━'.repeat(60));
    console.log(`  Total: ${Object.keys(groupedRoutes).length} routes`);
    console.log('━'.repeat(60) + '\n');
  }, 100);
}
```

**srv/routes/health.js**
```javascript
import { Router } from 'express';
import { testDatabaseConnection } from '../lib/db.js';
import { redisClient, redisCacheClient } from '../lib/resources.js';

const router = Router();

/**
 * ヘルスチェックエンドポイント
 * OpenAPI管理外の独立したエンドポイント
 */
router.get('/', async (req, res) => {
  const checks = {
    status: 'ok',
    timestamp: Math.floor(Date.now() / 1000),
    environment: process.env.NODE_ENV || 'development'
  };

  // データベースチェック
  try {
    const dbConnected = await testDatabaseConnection();
    checks.database = dbConnected ? 'ok' : 'error';
  } catch (error) {
    checks.database = 'error';
  }

  // Redisセッションチェック
  try {
    await redisClient.ping();
    checks.redis = 'ok';
  } catch (error) {
    checks.redis = 'error';
  }

  // Redisキャッシュチェック
  try {
    await redisCacheClient.ping();
    checks.redisCache = 'ok';
  } catch (error) {
    checks.redisCache = 'error';
  }

  // 全体のステータス判定
  const hasError = checks.database === 'error' || checks.redis === 'error' || checks.redisCache === 'error';
  if (hasError) {
    checks.status = 'error';
  }

  const statusCode = hasError ? 503 : 200;
  res.status(statusCode).json(checks);
});

export default router;
```

**srv/routes/auth.js**
```javascript
import express from 'express';
import bcrypt from 'bcrypt';
import { prisma } from '../lib/resources.js';
import { createSession, deleteSession, authenticate } from '../middleware/index.js';
import { ApiError, ErrorCodes } from '../lib/errors.js';
import { transformResponse } from '../lib/response-transformer.js';
import { ACL } from '../lib/acl.js';

const router = express.Router();

/**
 * POST /api/v1/auth/login
 * ユーザーログイン
 */
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // ユーザー検索
    const user = await prisma.users.findUnique({
      where: { email }
    });

    if (!user || !user.enabled) {
      throw new ApiError(401, ErrorCodes.INVALID_CREDENTIALS, 'Invalid credentials');
    }

    // パスワード検証 (password field, not passwordHash)
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      throw new ApiError(401, ErrorCodes.INVALID_CREDENTIALS, 'Invalid credentials');
    }

    // ACLインスタンスを作成 (IMPORTANT: Always use ACL class)
    const acl = new ACL(user.acl);

    // セッション作成
    const token = await createSession({
      id: user.id,
      email: user.email,
      name: user.name,
      permissions: acl.data  // Use normalized ACL data
    });

    // ユーザー情報を返す（パスワードは除外）
    return res.json({
      token,
      user: transformResponse(user, { exclude: ['password'] })
    });
  } catch (error) {
    return next(error);
  }
});

/**
 * POST /api/v1/auth/logout
 * ユーザーログアウト
 */
router.post('/logout', authenticate, async (req, res, next) => {
  try {
    await deleteSession(req.token);
    return res.json({ message: 'Logged out successfully' });
  } catch (error) {
    return next(error);
  }
});

/**
 * GET /api/v1/auth/me
 * 現在のユーザー情報取得
 */
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const user = await prisma.users.findUnique({
      where: { id: req.user.id }
    });

    if (!user) {
      throw new ApiError(404, ErrorCodes.USER_NOT_FOUND, 'User not found');
    }

    return res.json(transformResponse(user, { exclude: ['password'] }));
  } catch (error) {
    return next(error);
  }
});

export default router;
```

**srv/routes/users.js**
```javascript
import express from 'express';
import { prisma } from '../lib/resources.js';
import { authenticate } from '../middleware/index.js';
import { ApiError, ErrorCodes } from '../lib/errors.js';
import { transformResponse } from '../lib/response-transformer.js';

const router = express.Router();

// Get current user
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const user = await prisma.users.findUnique({
      where: { id: req.user.id }
    });
    
    if (!user) {
      throw new ApiError(404, ErrorCodes.USER_NOT_FOUND, 'User not found');
    }
    
    res.json(transformResponse(user, { exclude: ['password'] }));
  } catch (error) {
    next(error);
  }
});

// Update password
router.put('/me/password', authenticate, async (req, res, next) => {
  try {
    // Implementation here
    res.json({ message: 'Password updated successfully' });
  } catch (error) {
    next(error);
  }
});

export default router;
```

#### Frontend Skeleton

**src/App.vue**

```vue
<template>
  <v-app>
    <v-app-bar app>
      <v-toolbar-title>Project Name</v-toolbar-title>
    </v-app-bar>
    <v-main>
      <router-view />
    </v-main>
  </v-app>
</template>

<script>
export default {
  name: 'App'
};
</script>
```

**src/main.js**

```javascript
import { createApp } from 'vue';
import { createPinia } from 'pinia';
import App from './App.vue';
import router from './router';
import vuetify from './plugins/vuetify';

const app = createApp(App);

app.use(createPinia());
app.use(router);
app.use(vuetify);

app.mount('#app');
```

**src/plugins/vuetify.js**
```javascript
import 'vuetify/styles';
import '@mdi/font/css/materialdesignicons.css';
import { createVuetify } from 'vuetify';
import * as components from 'vuetify/components';
import * as directives from 'vuetify/directives';
import { ja } from 'vuetify/locale';

export default createVuetify({
  components,
  directives,
  theme: {
    defaultTheme: 'light',
    themes: {
      light: {
        colors: {
          primary: '#1976D2',
          secondary: '#424242',
          accent: '#82B1FF',
          error: '#FF5252',
          info: '#2196F3',
          success: '#4CAF50',
          warning: '#FFC107'
        }
      }
    }
  },
  locale: {
    locale: 'ja',
    messages: { ja }
  }
});
```

**src/plugins/axios.js**
```javascript
import axios from 'axios';
import Cookies from 'js-cookie';

const instance = axios.create({
  baseURL: '/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Request interceptor - Bearer token from cookie (API still uses Bearer auth)
instance.interceptors.request.use(
  (config) => {
    // Get token from cookie and send as Bearer token
    const token = Cookies.get('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor
instance.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Token invalid or expired
      Cookies.remove('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default instance;
```

**src/router/index.js**

```javascript
import { createRouter, createWebHistory } from 'vue-router';
import HomePage from '../pages/HomePage.vue';

const routes = [
  {
    path: '/',
    name: 'home',
    component: HomePage
  }
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

export default router;
```

**src/pages/HomePage.vue**

```vue
<template>
  <v-container>
    <v-row>
      <v-col cols="12">
        <h1>Welcome to Your Project</h1>
        <p>This is a skeleton application.</p>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
export default {
  name: 'HomePage'
};
</script>
```

**index.html**

```html
<!DOCTYPE html>
<html lang="ja">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Project Name</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
```

**srv/openapi/index.yaml**

```yaml
openapi: 3.0.0
info:
  title: Project API
  version: 1.0.0
  description: API specification

servers:
  - url: http://localhost:3000
    description: Development server

paths:
  # Health check is managed outside OpenAPI validation
  # Implemented in srv/routes/health.js

components:
  schemas:
    ErrorResponse:
      type: object
      required:
        - statusCode
        - code
        - errorCode
        - path
        - message
      properties:
        statusCode:
          type: integer
        code:
          type: string
          description: MD5 hash for error location
        errorCode:
          type: string
          description: Machine-readable error code
        path:
          type: string
        message:
          type: string
        errors:
          type: array
          items:
            type: object
            properties:
              field:
                type: string
              errorCode:
                type: string
              message:
                type: string
```

#### Support Scripts

**support/openapi-builder.js**

```javascript
#!/usr/bin/env node
import { execSync } from 'child_process';
import { existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Create dist directory if not exists
const distPath = './srv/openapi/dist';
if (!existsSync(distPath)) {
  mkdirSync(distPath, { recursive: true });
}

// Check if srv/openapi/index.yaml exists
if (!existsSync('./srv/openapi/index.yaml')) {
  console.error('Error: srv/openapi/index.yaml not found');
  console.log('Please create srv/openapi/index.yaml first');
  process.exit(1);
}

try {
  console.log('Building OpenAPI specification...');
  execSync('npx @redocly/cli bundle srv/openapi/index.yaml -o srv/openapi/dist/openapi.yaml', {
    stdio: 'inherit'
  });
  console.log('✓ OpenAPI specification built successfully');
} catch (error) {
  console.error('Failed to build OpenAPI specification');
  process.exit(1);
}
```

**support/openapi-validator.js**

```javascript
#!/usr/bin/env node
import { execSync } from 'child_process';

try {
  console.log('Validating OpenAPI specification...');
  execSync('npx @redocly/cli lint srv/openapi/index.yaml', {
    stdio: 'inherit'
  });
  console.log('✓ OpenAPI specification is valid');
} catch (error) {
  console.error('OpenAPI validation failed');
  process.exit(1);
}
```

#### Configuration File Skeleton

**config/default.json**

```json
{
  "server": {
    "port": 3000
  },
  "database": {
    "url": "mysql://root:password@localhost:3306/database_name"
  },
  "redis": {
    "host": "localhost",
    "port": 6379
  },
  "session": {
    "ttl": 86400
  }
}
```

**config/test.json**

```json
{
  "server": {
    "port": 3001
  },
  "database": {
    "url": "mysql://root:password@localhost:3306/test_database"
  },
  "redis": {
    "host": "localhost",
    "port": 6379,
    "db": 15
  },
  "session": {
    "ttl": 3600
  },
  "testAccounts": {
    "admin": {
      "email": "admin@example.com",
      "password": "admin123456",
      "name": "Test Admin",
      "role": "admin"
    },
    "user": {
      "email": "user@example.com",
      "password": "user123456",
      "name": "Test User",
      "role": "user"
    },
    "guest": {
      "email": "guest@example.com",
      "password": "guest123456",
      "name": "Test Guest",
      "role": "guest"
    }
  }
}
```

**.eslintrc.cjs**
```javascript
module.exports = {
  root: true,
  env: {
    node: true,
    es2022: true,
    browser: true
  },
  extends: [
    'airbnb-base',
    'plugin:vue/recommended'
  ],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module'
  },
  plugins: [
    'vue'
  ],
  rules: {
    'import/extensions': ['error', 'ignorePackages', {
      js: 'never',
      vue: 'always'
    }],
    'import/prefer-default-export': 'off',
    'no-console': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'warn' : 'off'
  },
  overrides: [
    // Test files configuration with Vitest plugin
    {
      files: [
        'tests/**/*.js',
        '**/*.spec.js',
        '**/*.test.js'
      ],
      plugins: ['@vitest'],
      extends: ['plugin:@vitest/legacy-recommended'],
      env: {
        node: true,
        '@vitest/env': true
      },
      rules: {
        'import/no-extraneous-dependencies': ['error', {
          devDependencies: true
        }],
        'no-console': 'off'
      }
    }
  ]
};
```

**vite.config.js**

```javascript
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import { fileURLToPath, URL } from 'node:url';

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: false
  }
});
```

**docker-compose.yml**

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.4
    container_name: project_mysql
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: database_name
      MYSQL_USER: dbuser
      MYSQL_PASSWORD: dbpassword
      TZ: Asia/Tokyo
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./sql:/docker-entrypoint-initdb.d
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci --default-time-zone='+09:00'

  redis:
    image: redis:7-alpine
    container_name: project_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

volumes:
  mysql_data:
  redis_data:
```

#### Prisma Schema Skeleton

**srv/prisma/schema.prisma**

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}

// Example model (will be replaced by db introspection)
model Users {
  id        Int      @id @default(autoincrement()) @map("id") @db.UnsignedInt
  email     String   @unique(map: "uk_users_email") @map("email") @db.VarChar(255)
  password  String   @map("password") @db.Char(60)  // Note: NOT passwordHash
  name      String   @map("name") @db.VarChar(255)
  enabled   Boolean  @default(true) @map("enabled")
  createdAt DateTime @default(now()) @map("created_at") @db.DateTime(0)
  updatedAt DateTime? @default(now()) @updatedAt @map("updated_at") @db.Timestamp(0)

  @@map("users")
  @@index([enabled], map: "idx_users_enabled")
}
```

**srv/prisma/seed.js**

```javascript
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  // Clear existing data (be careful in production)
  await prisma.users.deleteMany();

  // Create admin user with default password
  const hashedPassword = await bcrypt.hash('password123', 10);
  
  await prisma.users.create({
    data: {
      email: 'admin@example.com',
      password: hashedPassword,  // Note: password field, not passwordHash
      name: 'Administrator',
      enabled: true
    }
  });

  console.log('Seed data created successfully');
  console.log('Default login: admin@example.com / password123');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

**.dockerignore**

```text
node_modules
dist
.git
.gitignore
*.log
.DS_Store
.env*
coverage
.nyc_output
.idea
.vscode
```

## Initial Setup Procedure

1. Create directory structure (mkdir -p) - Note: Uses simplified 2-layer backend architecture
2. Place configuration files (.prettierrc, .eslintrc.js, .editorconfig, etc.)
3. Generate package.json (including prisma-case-format in devDependencies)
4. Create boilerplate files (including docker-compose.yml)
5. Create initial Prisma schema (srv/prisma/schema.prisma)
6. Create initial Prisma seed file (srv/prisma/seed.js)
7. Create initial OpenAPI specification (srv/openapi/index.yaml)
8. Set permissions for support scripts (chmod +x support/*.js)
9. Configure Git hooks (simple-git-hooks)
10. Run yarn install
11. **IMPORTANT**: Run yarn build:openapi before testing APIs
12. **Prisma Setup** (when database is ready):
    - `yarn prisma:sync` - Pull schema, format to camelCase, generate client
    - Or manually: `yarn prisma:pull && yarn prisma:format && yarn prisma:generate`
13. Initial operation check:
    - Check for port conflicts: `lsof -i :3000`
    - `yarn express` - Start backend (localhost:3000/api/v1/health)
    - `yarn serve` - Start frontend (localhost:5173)
    - `yarn build` - Build frontend to dist/
14. Database environment (if needed):
    - `docker-compose up -d` - Start MySQL/Redis
    - `yarn prisma:seed` - Seed with default data

## Minimum Startup Requirements

- Node.js 22+ (Volta recommended)
- Yarn 4+
- Docker/Docker Compose (when using MySQL/Redis)

## Critical Implementation Notes

### Express Middleware Order (MUST FOLLOW)
1. Basic middleware (express.json, CORS)
2. Response transformer
3. Health check route (BEFORE OpenAPI validator)
4. API routes registration
5. OpenAPI Validator (optional, after routes for Express 5)
6. Static file serving (production)
7. SPA fallback (MUST BE LAST)

### Field Naming Conventions
- Database: `password` (NOT `passwordHash`)
- Prisma Model: `Users` (plural, PascalCase)
- Response transformer: Automatically excludes `password` field
- Authentication: Uses `password` field for bcrypt comparison

### Frontend/Backend Integration
- Development: Separate servers (backend: 3000, frontend: 5173)
- Production: Single server serves both from port 3000
- Build: `yarn build` outputs to `dist/` directory
- SPA fallback: Handles client-side routing for non-API paths

## Notes

- Only responsible for initial setup when creating a project
- Implementation details are delegated to each agent
- Boilerplate contains only minimal working code
- Refer to each agent's documentation for detailed configuration file explanations
- Always check for port conflicts before starting servers
- Run `yarn build:openapi` before testing API endpoints

### Prisma-Specific Notes

- **prisma-case-format**: Automatically handles snake_case ↔ camelCase conversion
- **Database First**: Project uses database introspection, not code-first migrations
- **Naming Convention**: Database uses snake_case, code uses camelCase with @map directives
- **Script Shortcuts**: Use `yarn prisma:sync` for full schema refresh workflow
- **Manual Process**: Always run `yarn prisma:format:dry` first to preview changes

## Coordination

- **Each agent**: Add implementation details and customization
- **devops agent**: Docker Compose configuration
- **docs agent**: Documentation of setup procedures
