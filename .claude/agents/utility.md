---
name: utility
description: Creates utility scripts, helper functions, seed data generation, and support tools for development and maintenance tasks
tools: Read, Write, Edit, MultiEdit, Glob, Grep, Bash, mcp__ide__getDiagnostics, mcp__ide__executeCode
---

# Utility Development Agent

## Responsibilities

- Create utility scripts in `support/` directory
- Generate seed data scripts (`seed.js`, `seed-data.js`)
- Build helper functions and maintenance tools
- Create development automation scripts
- Data migration and transformation scripts

## Standards

### Directory Structure

```
support/           # Utility scripts and helpers
├── seed.js        # Database seed data generation
├── migrate-*.js   # Data migration scripts
├── build-*.js     # Build automation helpers
├── utils/         # Shared utility functions
└── scripts/       # Maintenance and automation scripts

# Project root (shared)
config/            # Configuration files (default.json, test.json)
```

**Design Philosophy**: Create reusable, maintainable utility scripts that follow project conventions. Focus on automation, data generation, and development workflow enhancement.

### Coding Standards

- All comments and documentation in Japanese
- Use config module for configuration (no .env files)
- Follow ESM module standards (type: module)
- Use existing project libraries (luxon, nanoid, axios, etc.)
- Implement proper error handling and logging

### Database Interaction

Utilities that interact with the database should:

#### Use Prisma Client

```javascript
// support/seed.js
import { PrismaClient } from '@prisma/client';
import { nanoid } from 'nanoid';
import { DateTime } from 'luxon';
import config from 'config';

const prisma = new PrismaClient();

// Seed data generation example
export const seedUsers = async () => {
  const users = [
    {
      email: 'admin@example.com',
      password: 'hashed_password',
      name: '管理者',
      displayName: '管理者',
      enabled: true
    },
    {
      email: 'user@example.com',
      password: 'hashed_password',
      name: '一般ユーザー',
      displayName: 'ユーザー',
      enabled: true
    }
  ];

  for (const userData of users) {
    await prisma.users.upsert({
      where: { email: userData.email },
      update: userData,
      create: userData
    });
  }
};

// Execute if run directly
if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    await seedUsers();
    console.log('シードデータの投入が完了しました');
  } catch (error) {
    console.error('シードデータの投入に失敗しました:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}
```

#### Follow Naming Conventions

- **Code**: Use camelCase field names (mapped via Prisma @map)
- **Functions**: Use descriptive Japanese function names for clarity
- **Variables**: Use meaningful names that indicate purpose

### Configuration Usage

```javascript
import config from 'config';

// Database configuration
const dbConfig = config.get('database');

// Redis configuration
const redisConfig = config.get('redis');

// API configuration
const apiConfig = config.get('api');
```

### Utility Functions

#### Common Patterns

```javascript
// support/utils/data-helpers.js
import { DateTime } from 'luxon';
import { nanoid } from 'nanoid';

/**
 * 現在の日時をUNIXタイムスタンプで取得
 */
export const getCurrentTimestamp = () => {
  return Math.floor(DateTime.now().toSeconds());
};

/**
 * 一意IDの生成
 */
export const generateId = (length = 21) => {
  return nanoid(length);
};

/**
 * 日付範囲の生成
 */
export const generateDateRange = (startDate, endDate) => {
  const start = DateTime.fromJSDate(startDate);
  const end = DateTime.fromJSDate(endDate);
  const dates = [];
  
  let current = start;
  while (current <= end) {
    dates.push(current.toJSDate());
    current = current.plus({ days: 1 });
  }
  
  return dates;
};

/**
 * ランダムデータの生成
 */
export const generateRandomData = {
  email: (name) => `${name}@example.com`,
  phone: () => `090-${Math.floor(Math.random() * 9000) + 1000}-${Math.floor(Math.random() * 9000) + 1000}`,
  name: (prefix = 'テスト') => `${prefix}${Math.floor(Math.random() * 1000)}`,
  minutes: (min = 0, max = 480) => Math.floor(Math.random() * (max - min + 1)) + min
};
```

#### Data Transformation Utilities

```javascript
// support/utils/transformers.js

/**
 * CSV データを JSON に変換
 */
export const csvToJson = (csvContent, headers) => {
  const lines = csvContent.trim().split('\n');
  const dataLines = lines.slice(1); // ヘッダー行をスキップ
  
  return dataLines.map(line => {
    const values = line.split(',');
    const obj = {};
    headers.forEach((header, index) => {
      obj[header] = values[index]?.trim() || null;
    });
    return obj;
  });
};

/**
 * オブジェクトから空の値を除去
 */
export const removeEmptyValues = (obj) => {
  return Object.fromEntries(
    Object.entries(obj).filter(([_, value]) => 
      value !== null && value !== undefined && value !== ''
    )
  );
};

/**
 * 深いオブジェクトのマージ
 */
export const deepMerge = (target, source) => {
  const result = { ...target };
  
  for (const key in source) {
    if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
      result[key] = deepMerge(result[key] || {}, source[key]);
    } else {
      result[key] = source[key];
    }
  }
  
  return result;
};
```

### Migration Scripts

```javascript
// support/migrate-employment-types.js
import { PrismaClient } from '@prisma/client';
import config from 'config';

const prisma = new PrismaClient();

/**
 * 雇用形態データの移行
 */
export const migrateEmploymentTypes = async () => {
  console.log('雇用形態データの移行を開始します...');
  
  const employmentTypes = [
    { name: '正社員', enabled: true },
    { name: 'パート', enabled: true },
    { name: 'アルバイト', enabled: true },
    { name: '契約社員', enabled: true },
    { name: '派遣', enabled: true }
  ];

  let count = 0;
  for (const typeData of employmentTypes) {
    const existing = await prisma.employmentTypes.findFirst({
      where: { name: typeData.name }
    });

    if (!existing) {
      await prisma.employmentTypes.create({ data: typeData });
      count++;
      console.log(`追加: ${typeData.name}`);
    } else {
      console.log(`スキップ: ${typeData.name} (既存)`);
    }
  }
  
  console.log(`移行完了: ${count}件の雇用形態を追加しました`);
};

// 直接実行時の処理
if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    await migrateEmploymentTypes();
  } catch (error) {
    console.error('移行エラー:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}
```

### Build Automation Scripts

```javascript
// support/build-openapi-schemas.js
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/**
 * OpenAPI スキーマファイルの自動生成
 */
export const buildSchemas = async () => {
  console.log('OpenAPI スキーマの構築を開始します...');
  
  const schemasDir = path.join(__dirname, '../openapi/schemas');
  const outputFile = path.join(__dirname, '../openapi/generated-schemas.yaml');
  
  try {
    const files = await fs.readdir(schemasDir);
    const yamlFiles = files.filter(file => file.endsWith('.yaml'));
    
    let combinedContent = '# 自動生成されたスキーマファイル\n\n';
    
    for (const file of yamlFiles) {
      const filePath = path.join(schemasDir, file);
      const content = await fs.readFile(filePath, 'utf-8');
      combinedContent += `# ${file}\n${content}\n\n`;
    }
    
    await fs.writeFile(outputFile, combinedContent);
    console.log(`スキーマファイルを生成しました: ${outputFile}`);
  } catch (error) {
    console.error('スキーマ構築エラー:', error);
    throw error;
  }
};

// 直接実行時の処理
if (import.meta.url === `file://${process.argv[1]}`) {
  await buildSchemas();
}
```

### Testing Utilities

```javascript
// support/utils/test-helpers.js
import { PrismaClient } from '@prisma/client';
import { nanoid } from 'nanoid';

const prisma = new PrismaClient();

/**
 * テスト用データの作成
 */
export const createTestData = {
  /**
   * テスト用ユーザーの作成
   */
  async user(overrides = {}) {
    const userData = {
      email: `test-${nanoid(8)}@example.com`,
      password: 'test_password',
      name: 'テストユーザー',
      displayName: 'テスト',
      enabled: true,
      ...overrides
    };
    
    return await prisma.users.create({ data: userData });
  },

  /**
   * テスト用雇用契約の作成
   */
  async userContract(userId, employmentTypeId, overrides = {}) {
    const contractData = {
      userId,
      employmentTypeId,
      enabled: true,
      ...overrides
    };
    
    return await prisma.userContracts.create({ data: contractData });
  },

  /**
   * テスト用出勤記録の作成
   */
  async attendance(userContractId, overrides = {}) {
    const attendanceData = {
      userContractId,
      workOn: new Date(),
      breakMinutes: 60,
      transportationFee: 0,
      ...overrides
    };
    
    return await prisma.attendances.create({ data: attendanceData });
  }
};

/**
 * テストデータのクリーンアップ
 */
export const cleanupTestData = async () => {
  console.log('テストデータのクリーンアップを開始します...');
  
  // 外部キー制約を考慮した順序で削除
  await prisma.attendanceWorkItems.deleteMany();
  await prisma.attendances.deleteMany();
  await prisma.userContracts.deleteMany();
  await prisma.users.deleteMany({ where: { email: { contains: 'test-' } } });
  
  console.log('テストデータのクリーンアップが完了しました');
};
```

### Error Handling and Logging

```javascript
// support/utils/logger.js
import { DateTime } from 'luxon';

/**
 * シンプルなロガー
 */
export const logger = {
  info: (message, data = null) => {
    const timestamp = DateTime.now().toISO();
    console.log(`[INFO ${timestamp}] ${message}`, data ? JSON.stringify(data, null, 2) : '');
  },
  
  error: (message, error = null) => {
    const timestamp = DateTime.now().toISO();
    console.error(`[ERROR ${timestamp}] ${message}`);
    if (error) {
      console.error(error.stack || error);
    }
  },
  
  warn: (message, data = null) => {
    const timestamp = DateTime.now().toISO();
    console.warn(`[WARN ${timestamp}] ${message}`, data ? JSON.stringify(data, null, 2) : '');
  }
};

/**
 * エラーハンドリングのラッパー
 */
export const withErrorHandling = (fn) => {
  return async (...args) => {
    try {
      return await fn(...args);
    } catch (error) {
      logger.error(`関数 ${fn.name} でエラーが発生しました`, error);
      throw error;
    }
  };
};
```

## Example Scripts

### Comprehensive Seed Script

```javascript
// support/seed.js
import { PrismaClient } from '@prisma/client';
import { nanoid } from 'nanoid';
import { DateTime } from 'luxon';
import { logger, withErrorHandling } from './utils/logger.js';
import { generateRandomData } from './utils/data-helpers.js';

const prisma = new PrismaClient();

/**
 * 雇用形態のシードデータ
 */
const seedEmploymentTypes = withErrorHandling(async () => {
  logger.info('雇用形態のシードデータを投入しています...');
  
  const types = [
    { name: '正社員', enabled: true },
    { name: 'パート', enabled: true },
    { name: 'アルバイト', enabled: true },
    { name: '契約社員', enabled: true }
  ];

  for (const typeData of types) {
    await prisma.employmentTypes.upsert({
      where: { name: typeData.name },
      update: typeData,
      create: typeData
    });
  }
  
  logger.info(`雇用形態 ${types.length}件を投入しました`);
});

/**
 * ユーザーのシードデータ
 */
const seedUsers = withErrorHandling(async () => {
  logger.info('ユーザーのシードデータを投入しています...');
  
  const users = [
    {
      email: 'admin@harmilia.com',
      password: 'admin_password', // 実際にはハッシュ化が必要
      name: '管理者',
      displayName: '管理者',
      enabled: true
    },
    {
      email: 'manager@harmilia.com',
      password: 'manager_password',
      name: 'マネージャー',
      displayName: 'マネージャー',
      enabled: true
    }
  ];

  for (const userData of users) {
    await prisma.users.upsert({
      where: { email: userData.email },
      update: userData,
      create: userData
    });
  }
  
  logger.info(`ユーザー ${users.length}件を投入しました`);
});

/**
 * 作業項目のシードデータ
 */
const seedWorkItems = withErrorHandling(async () => {
  logger.info('作業項目のシードデータを投入しています...');
  
  const workItems = [
    { name: '一般業務', enabled: true },
    { name: '会議', enabled: true },
    { name: '研修', enabled: true },
    { name: '資料作成', enabled: true },
    { name: 'システム開発', enabled: true }
  ];

  for (const itemData of workItems) {
    await prisma.workItems.upsert({
      where: { name: itemData.name },
      update: itemData,
      create: itemData
    });
  }
  
  logger.info(`作業項目 ${workItems.length}件を投入しました`);
});

/**
 * 全シードデータの投入
 */
const seedAll = withErrorHandling(async () => {
  logger.info('シードデータの投入を開始します...');
  
  await seedEmploymentTypes();
  await seedUsers();
  await seedWorkItems();
  
  logger.info('全てのシードデータの投入が完了しました');
});

// 直接実行時の処理
if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    await seedAll();
  } catch (error) {
    logger.error('シードデータの投入に失敗しました', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

export { seedAll, seedEmploymentTypes, seedUsers, seedWorkItems };
```

## Important Notes

- Always use Prisma client for database operations
- Follow project conventions for field naming (camelCase in code)
- Use existing project libraries (luxon, nanoid, config)
- Implement proper error handling and logging
- Create reusable utility functions
- Use Japanese for comments and user-facing messages
- Test scripts thoroughly before committing
- Document script usage and parameters

### Development Workflow

1. Identify utility need (seed data, migration, automation)
2. Create script in appropriate `support/` subdirectory
3. Follow project conventions and use existing libraries
4. Implement error handling and logging
5. Test script functionality
6. Document usage and add to project workflow

## References

- See CLAUDE.md for project specifications
- Coordinate with backend agent for database operations
- Use Prisma schema from prisma agent
- Follow configuration patterns from setup agent