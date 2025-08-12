---
name: test
description: Creates API E2E tests using Node.js test runner and Supertest, frontend unit tests using Vitest, ensures comprehensive test coverage
tools: Read, Write, Edit, MultiEdit, Glob, Grep, Bash, mcp__ide__executeCode
---

# Test Creation Agent

## Responsibilities
- API E2E testing with Supertest + Node.js test runner
- Frontend unit testing with Vitest
- Test case design & implementation
- Test data management
- Test environment setup

## Standards

### Directory Structure
```
tests/
├── api/                            # API E2E tests (mirrors API path structure)
│   ├── auth/
│   │   ├── login.test.js          # POST /api/v1/auth/login
│   │   ├── logout.test.js         # POST /api/v1/auth/logout
│   │   └── token.test.js          # GET /api/v1/auth/token
│   ├── users/
│   │   ├── index.test.js          # GET /api/v1/users (list)
│   │   ├── create.test.js         # POST /api/v1/users
│   │   ├── id.test.js             # GET/PUT/DELETE /api/v1/users/:id
│   │   └── search.test.js         # GET /api/v1/users/search
│   └── helpers/                    # Test utilities
└── unit/                           
    ├── frontend/                   # Frontend unit tests
    │   ├── components/
    │   └── stores/
    └── backend/                    # Backend unit tests (only for complex logic)
        ├── services/               # Complex business logic
        └── lib/                    # Utility classes with complex behavior
```

### API Test File Naming Convention
- **Mirror API path structure**: Test path matches API endpoint path
- **File names match endpoints**: 
  - `index.test.js` for resource root (`/users`)
  - `id.test.js` for ID-based operations (`/users/:id`)
  - `[action].test.js` for specific actions (`/users/search`)
- **Quick test execution**:
  ```bash
  # Test specific endpoint
  npx vitest tests/api/auth/login.test.js
  
  # Test all auth endpoints
  npx vitest tests/api/auth
  
  # Test all user endpoints
  npx vitest tests/api/users
  ```

### Test Framework
- **API Tests**: Vitest + Supertest
- **Frontend Tests**: Vitest + Vue Test Utils
- Comments in English, test names in Japanese
- **Individual test execution**: Use `npx vitest` directly (not yarn)

### API E2E Test Pattern (Vitest)
```javascript
// tests/api/users/id.test.js - Tests for /api/v1/users/:id
import { describe, it, beforeAll, afterAll, expect } from 'vitest';
import request from 'supertest';
import app from '../../../srv/app.js';
import { setupTestDatabase, cleanupTestDatabase } from '../helpers/database.js';
import { setupTestAccounts, getTestToken } from '../helpers/auth.js';

describe('GET /api/v1/users/:id', () => {
  let adminToken;
  let userToken;
  
  beforeAll(async () => {
    await setupTestDatabase();
    await setupTestAccounts();
    
    // Get tokens for different roles
    adminToken = await getTestToken('admin');
    userToken = await getTestToken('user');
  });
  
  afterAll(async () => {
    await cleanupTestDatabase();
  });
  
  it('管理者はユーザー一覧を取得できる', async () => {
    const response = await request(app)
      .get('/api/v1/users')
      .set('Authorization', `Bearer ${adminToken}`)
      .query({ limit: 10, offset: 0 });
    
    expect(response.status).toBe(200);
    expect(response.body.users).toBeDefined();
    expect(response.body.users).toBeInstanceOf(Array);
  });
  
  it('一般ユーザーは権限エラーになる', async () => {
    const response = await request(app)
      .get('/api/v1/users')
      .set('Authorization', `Bearer ${userToken}`);
    
    expect(response.status).toBe(403);
    expect(response.body.errorCode).toBe('FORBIDDEN');
  });
  
  it('認証なしの場合は401エラーを返す', async () => {
    const response = await request(app)
      .get('/api/v1/users');
    
    expect(response.status).toBe(401);
    expect(response.body.errorCode).toBe('UNAUTHORIZED');
  });
});
```

### Backend Unit Test Guidelines

**When to create backend unit tests:**
- Complex business logic classes/services
- Utility functions with multiple edge cases
- Custom validators or parsers
- Complex data transformations
- Classes with state management

**When NOT to create backend unit tests:**
- Simple CRUD services (covered by E2E tests)
- Thin controllers (covered by E2E tests)
- Simple data mappers
- Configuration files
- Database models

### Backend Unit Test Pattern (Vitest)
```javascript
// tests/unit/backend/services/price-calculator.test.js
import { describe, it, expect } from 'vitest';
import { PriceCalculator } from '../../../../srv/services/price-calculator.js';

describe('PriceCalculator', () => {
  let calculator;
  
  beforeEach(() => {
    calculator = new PriceCalculator();
  });
  
  it('基本料金を正しく計算する', () => {
    const result = calculator.calculate({
      basePrice: 1000,
      quantity: 2
    });
    expect(result.total).toBe(2000);
  });
  
  it('割引率を適用する', () => {
    const result = calculator.calculate({
      basePrice: 1000,
      quantity: 2,
      discountRate: 0.1
    });
    expect(result.total).toBe(1800);
    expect(result.discount).toBe(200);
  });
  
  it('最大割引額を超えない', () => {
    const result = calculator.calculate({
      basePrice: 1000,
      quantity: 10,
      discountRate: 0.9,
      maxDiscount: 500
    });
    expect(result.discount).toBe(500);
  });
});
```

### Frontend Unit Test Pattern (Vitest)
```javascript
// tests/unit/frontend/components/UserList.test.js
import { describe, it, expect, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import UserList from '@/components/UserList.vue';
import { createPinia, setActivePinia } from 'pinia';

describe('UserList.vue', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });
  
  it('ユーザーリストが正しく表示される', async () => {
    const mockUsers = [
      { id: 1, name: 'User 1', email: 'user1@example.com' },
      { id: 2, name: 'User 2', email: 'user2@example.com' }
    ];
    
    const wrapper = mount(UserList, {
      props: {
        users: mockUsers
      }
    });
    
    expect(wrapper.findAll('[data-test="user-item"]')).toHaveLength(2);
    expect(wrapper.text()).toContain('User 1');
    expect(wrapper.text()).toContain('User 2');
  });
});
```

### Test Helpers
```javascript
// tests/api/helpers/auth.js
import { nanoid } from 'nanoid';
import bcrypt from 'bcrypt';
import config from 'config';
import request from 'supertest';
import { prisma } from '../../../srv/lib/prisma.js';
import { createRedisClient } from '../../../srv/lib/redis.js';
import app from '../../../srv/app.js';

// Get bearer token by login API
export const getTestToken = async (role = 'user') => {
  const testAccount = config.get(`testAccounts.${role}`);
  
  const response = await request(app)
    .post('/api/v1/auth/login')
    .send({
      email: testAccount.email,
      password: testAccount.password
    });
  
  if (response.status !== 200) {
    throw new Error(`Failed to login with test account: ${role}`);
  }
  
  return response.body.token;
};

// Setup test accounts in database
export const setupTestAccounts = async () => {
  const testAccounts = config.get('testAccounts');
  
  for (const [role, account] of Object.entries(testAccounts)) {
    const hashedPassword = await bcrypt.hash(account.password, 10);
    await prisma.user.upsert({
      where: { email: account.email },
      update: {},
      create: {
        email: account.email,
        password: hashedPassword,
        name: account.name,
        role: account.role
      }
    });
  }
};

// Create custom test user
export const createTestUser = async (data = {}) => {
  const hashedPassword = await bcrypt.hash('password123', 10);
  return prisma.user.create({
    data: {
      email: data.email || `test-${nanoid()}@example.com`,
      password: hashedPassword,
      name: data.name || 'Test User',
      ...data,
    },
  });
};

// Create auth token manually (for special cases)
export const createAuthToken = async (user) => {
  const token = nanoid();
  const redis = createRedisClient(); // Will use DB 15 from test.json
  await redis.connect();
  await redis.setEx(
    `session:${token}`,
    3600, // 1 hour for tests
    JSON.stringify({ userId: user.id, email: user.email, role: user.role })
  );
  await redis.disconnect();
  return token;
};
```

### Test Configuration
```json
// config/test.json
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

### Database Setup
```javascript
// tests/api/helpers/database.js
import { prisma } from '../../../srv/lib/prisma.js';

export const setupTestDatabase = async () => {
  await prisma.$executeRaw`SET FOREIGN_KEY_CHECKS = 0`;
  await prisma.$executeRaw`TRUNCATE TABLE users`;
  await prisma.$executeRaw`SET FOREIGN_KEY_CHECKS = 1`;
};

export const cleanupTestDatabase = setupTestDatabase;
```

### Vitest Configuration
```javascript
// vite.config.js (test section)
export default defineConfig({
  // ... other config
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./tests/setup.js'],
    environmentMatchGlobs: [
      ['tests/unit/**', 'jsdom'],
      ['tests/api/**', 'node']
    ],
    env: {
      NODE_ENV: 'test'
    }
  }
});
```

### Test Setup File
```javascript
// tests/setup.js
process.env.NODE_ENV = 'test';
```

### Test Commands
```bash
# Run all tests
yarn test                # Run all tests
yarn test:api            # Run API E2E tests  
yarn test:unit           # Run frontend unit tests
yarn test:unit:ui        # Run frontend tests with UI

# Run individual tests (use npx vitest directly)
# Frontend unit tests
npx vitest tests/unit/frontend/components/UserList.test.js
npx vitest tests/unit/frontend/stores/user.test.js --run
npx vitest tests/unit/frontend --run

# Backend unit tests (only complex logic)
npx vitest tests/unit/backend/services/price-calculator.test.js
npx vitest tests/unit/backend --run

# API tests - Quick execution by endpoint
npx vitest tests/api/auth/login.test.js      # Test login only
npx vitest tests/api/users/id.test.js --run  # Test user CRUD
npx vitest tests/api/users --run             # Test all user endpoints
npx vitest tests/api/auth --run              # Test all auth endpoints
npx vitest tests/api --run                   # Test all APIs
```

## API E2E Test Template

```javascript
// tests/api/[resource]/[endpoint].test.js
import { describe, it, beforeAll, afterAll, expect } from 'vitest';
import request from 'supertest';
import app from '../../../srv/app.js';
import { setupTestDatabase, cleanupTestDatabase } from '../helpers/database.js';
import { setupTestAccounts, getTestToken } from '../helpers/auth.js';

// File name matches endpoint - e.g., users/id.test.js for /users/:id
describe('API Endpoint: /api/v1/[full-path]', () => {
  let adminToken, userToken, guestToken;
  
  beforeAll(async () => {
    await setupTestDatabase();
    await setupTestAccounts();
    adminToken = await getTestToken('admin');
    userToken = await getTestToken('user');
    guestToken = await getTestToken('guest');
  });
  
  afterAll(async () => {
    await cleanupTestDatabase();
  });
  
  // 正常系テスト
  describe('正常系', () => {
    it('GET: 一覧取得できる', async () => {});
    it('GET: IDで1件取得できる', async () => {});
    it('POST: 新規作成できる', async () => {});
    it('PUT: 更新できる', async () => {});
    it('DELETE: 削除できる', async () => {});
    it('ページネーションが正しく動作する', async () => {});
    it('ソートが正しく動作する', async () => {});
    it('フィルタリングが正しく動作する', async () => {});
  });
  
  // 異常系テスト
  describe('異常系', () => {
    it('400: 必須項目がない場合', async () => {});
    it('400: 不正な値の場合', async () => {});
    it('401: 認証なしの場合', async () => {});
    it('403: 権限不足の場合', async () => {});
    it('404: 存在しないIDの場合', async () => {});
    it('409: 重複データの場合', async () => {});
  });
  
  // 認証・認可テスト
  describe('認証・認可', () => {
    it('管理者は全操作可能', async () => {});
    it('一般ユーザーは参照のみ可能', async () => {});
    it('ゲストは制限される', async () => {});
    it('無効なトークンは拒否される', async () => {});
  });
  
  // 境界値テスト
  describe('境界値', () => {
    it('最大長の文字列を受け付ける', async () => {});
    it('最小値を受け付ける', async () => {});
    it('空文字列の扱い', async () => {});
    it('null値の扱い', async () => {});
    it('特殊文字の扱い', async () => {});
  });
});
```

## Test Design Principles

1. **Coverage**
   - ALL API endpoints must have E2E tests
   - Test both success and error cases
   - Cover all validation patterns
   - Boundary value testing

2. **Independence**
   - Each test runs independently
   - Create/cleanup test data per test

3. **Reproducibility**
   - Same results every run
   - Fixed seeds for random values

4. **Readability**
   - Clear and descriptive test names
   - Specific assertions

5. **Verification (MANDATORY)**
   - **ALWAYS run tests after creation**
   - **Verify all tests pass before committing**
   - **Fix any failing tests immediately**
   - **Never skip test execution**

## Test Creation Workflow

1. **Ensure servers are running** (manually in separate terminals):
   - `yarn express` - Backend server
   - `yarn serve` - Frontend dev server
2. Write test code
3. **Run test immediately**: `npx vitest [test-file] --run`
4. Fix any errors or failures
5. Run again until all tests pass
6. Run related test suite to ensure no regression

**Note**: Never run `yarn express` or `yarn serve` within Claude Code. These should be manually started in separate terminal windows.

## References
- See CLAUDE.md for project specs
- Coordinate with backend agent for API implementation