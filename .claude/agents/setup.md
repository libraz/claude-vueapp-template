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
├── openapi/             # OpenAPI specifications
│   └── components/      # Shared schemas
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
│   ├── config/
│   ├── controllers/
│   ├── lib/
│   ├── middleware/
│   ├── routes/
│   └── services/
├── support/             # Helper scripts
└── tests/               # Tests
    ├── api/             # API E2E tests (supertest)
    └── unit/            # Frontend unit tests
```

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
.vscode/
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
openapi/dist/

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
    "update:check": "ncu",
    "update:minor": "ncu -u --target minor",
    "update:patch": "ncu -u --target patch",
    "update:all": "ncu -u"
  },
  "dependencies": {
    "express": "^4.0.0",
    "@prisma/client": "^5.0.0",
    "config": "^3.0.0",
    "luxon": "^3.0.0",
    "nanoid": "^5.0.0",
    "axios": "^1.0.0",
    "js-cookie": "^3.0.0",
    "express-openapi-validator": "^5.0.0",
    "js-yaml": "^4.0.0",
    "redis": "^4.0.0",
    "vue": "^3.0.0",
    "vuetify": "^3.0.0",
    "@mdi/font": "^7.0.0",
    "pinia": "^2.0.0",
    "vue-router": "^4.0.0"
  },
  "devDependencies": {
    "prisma": "^5.0.0",
    "@vitejs/plugin-vue": "^5.0.0",
    "vite": "^5.0.0",
    "nodemon": "^3.0.0",
    "concurrently": "^8.0.0",
    "eslint": "^8.0.0",
    "eslint-config-airbnb-base": "^15.0.0",
    "eslint-plugin-import": "^2.0.0",
    "eslint-plugin-vue": "^9.0.0",
    "prettier": "^3.0.0",
    "@redocly/cli": "^1.0.0",
    "simple-git-hooks": "^2.0.0",
    "npm-check-updates": "^17.0.0",
    "supertest": "^6.0.0",
    "vitest": "^1.0.0",
    "@vue/test-utils": "^2.0.0",
    "@vitest/ui": "^1.0.0",
    "markdownlint-cli": "^0.41.0"
  }
}
```

#### Backend Skeleton

**srv/app.js**

```javascript
import express from 'express';
import config from 'config';
import OpenApiValidator from 'express-openapi-validator';
import { readFileSync } from 'fs';
import { load } from 'js-yaml';
import { errorHandler } from './lib/error-handler.js';
import { HttpError } from './lib/http-error.js';

const app = express();
const PORT = config.get('server.port');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// OpenAPI validation (skip on error)
try {
  const apiSpec = load(readFileSync('./openapi/dist/openapi.yaml', 'utf8'));
  app.use(OpenApiValidator.middleware({
    apiSpec,
    validateRequests: true,
    validateResponses: true,
    validateFormats: 'full'
  }));
  
  // Convert validation errors to HttpError
  app.use((err, req, res, next) => {
    if (err.status === 400 && err.errors) {
      const httpError = new HttpError(400, 'Validation failed', 'VALIDATION_ERROR');
      httpError.errors = err.errors.map(e => ({
        field: e.path,
        errorCode: e.errorCode || 'INVALID_VALUE',
        message: e.message
      }));
      next(httpError);
    } else {
      next(err);
    }
  });
} catch (error) {
  console.warn('OpenAPI spec not found. Validation disabled.');
}

// Health check endpoint
app.get('/api/v1/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handler
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default app;
```

**srv/lib/http-error.js**
```javascript
export class HttpError extends Error {
  constructor(statusCode, message, errorCode) {
    super(message);
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.errors = null;
  }
}
```

**srv/lib/prisma.js**
```javascript
import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error']
});
```

**srv/lib/redis.js**

```javascript
import { createClient } from 'redis';
import config from 'config';

const redisConfig = config.get('redis');

// Redis connection (minimal initial implementation)
export const createRedisClient = (database) => {
  // Use database from config if not specified
  const db = database !== undefined ? database : (redisConfig.db || 0);
  
  const client = createClient({
    host: redisConfig.host,
    port: redisConfig.port,
    database: db
  });
  
  client.on('error', (err) => console.error(`Redis Error (DB${db}):`, err));
  
  return client;
};
```

**srv/lib/error-handler.js**

```javascript
import crypto from 'crypto';
import { HttpError } from './http-error.js';

export const generateErrorCode = (req) => {
  const data = `${req.method}:${req.path}:${new Date().toISOString()}`;
  return crypto.createHash('md5').update(data).digest('hex');
};

export const errorHandler = (err, req, res, next) => {
  if (err instanceof HttpError) {
    res.status(err.statusCode).json({
      statusCode: err.statusCode,
      code: generateErrorCode(req),
      errorCode: err.errorCode,
      path: req.path,
      message: err.message,
      errors: err.errors || undefined
    });
  } else {
    console.error(err);
    res.status(500).json({
      statusCode: 500,
      code: generateErrorCode(req),
      errorCode: 'INTERNAL_SERVER_ERROR',
      path: req.path,
      message: 'Internal server error'
    });
  }
};
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
    defaultTheme: 'light'
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

**openapi/index.yaml**

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
  /api/v1/health:
    get:
      summary: Health check
      operationId: getHealth
      tags:
        - System
      responses:
        '200':
          description: System is healthy
          content:
            application/json:
              schema:
                type: object
                required:
                  - status
                  - timestamp
                properties:
                  status:
                    type: string
                    enum: [ok]
                  timestamp:
                    type: string
                    format: date-time

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
const distPath = './openapi/dist';
if (!existsSync(distPath)) {
  mkdirSync(distPath, { recursive: true });
}

// Check if openapi/index.yaml exists
if (!existsSync('./openapi/index.yaml')) {
  console.error('Error: openapi/index.yaml not found');
  console.log('Please create openapi/index.yaml first');
  process.exit(1);
}

try {
  console.log('Building OpenAPI specification...');
  execSync('npx @redocly/cli bundle openapi/index.yaml -o openapi/dist/openapi.yaml', {
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
  execSync('npx @redocly/cli lint openapi/index.yaml', {
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

**.eslintrc.js**
```javascript
module.exports = {
  root: true,
  extends: [
    'airbnb-base',
    'plugin:vue/vue3-recommended'
  ],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module'
  },
  rules: {
    'import/extensions': ['error', 'ignorePackages'],
    'import/prefer-default-export': 'off',
    'no-console': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'warn' : 'off'
  }
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
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true
      }
    }
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

1. Create directory structure (mkdir -p)
2. Place configuration files (.prettierrc, .eslintrc.js, .editorconfig, etc.)
3. Generate package.json
4. Create boilerplate files (including docker-compose.yml)
5. Create initial OpenAPI specification (openapi/index.yaml)
6. Set permissions for support scripts (chmod +x support/*.js)
7. Configure Git hooks (simple-git-hooks)
8. Run yarn install
9. Run yarn build:openapi (build OpenAPI specification)
10. Initial operation check (run manually in separate terminals):
    - `yarn express` - Start backend (localhost:3000/api/v1/health)
    - `yarn serve` - Start frontend (localhost:5173)
    - **Note**: Do not run within Claude Code
11. Database environment (if needed):
    - `docker-compose up -d` - Start MySQL/Redis

## Minimum Startup Requirements

- Node.js 22+ (Volta recommended)
- Yarn 4+
- Docker/Docker Compose (when using MySQL/Redis)

## Notes

- Only responsible for initial setup when creating a project
- Implementation details are delegated to each agent
- Boilerplate contains only minimal working code
- Refer to each agent's documentation for detailed configuration file explanations

## Coordination

- **Each agent**: Add implementation details and customization
- **devops agent**: Docker Compose configuration
- **docs agent**: Documentation of setup procedures
