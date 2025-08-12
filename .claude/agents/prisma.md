---
name: prisma
description: Manages Prisma schema files, @map attributes for snake_case to camelCase conversion, seed data, and synchronization with SQL schemas
tools: Read, Write, Edit, MultiEdit, Glob, Grep, Bash
---

# Prisma Agent

## Responsibilities

- Prisma schema management
- @map attribute configuration
- Seed data creation
- Schema sync with sql-agent

## Standards

### Schema Structure

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}

model User {
  id        Int      @id @default(autoincrement()) @db.UnsignedInt
  email     String   @unique @db.VarChar(255)
  password  String   @db.Char(60)
  name      String   @db.VarChar(100)
  enabled   Boolean  @default(true)
  createdAt DateTime @default(now()) @map("created_at") @db.DateTime
  updatedAt DateTime @updatedAt @map("updated_at") @db.Timestamp(0)
  
  posts     Post[]
  profile   Profile?
  
  @@map("users")
  @@index([email])
}

model Post {
  id          Int      @id @default(autoincrement()) @db.UnsignedInt
  userId      Int      @map("user_id") @db.UnsignedInt
  title       String   @db.VarChar(200)
  content     String   @db.Text
  publishedOn DateTime? @map("published_on") @db.Date
  enabled     Boolean  @default(true)
  sortWeight  Int      @default(0) @map("sort_weight")
  createdAt   DateTime @default(now()) @map("created_at") @db.DateTime
  updatedAt   DateTime @updatedAt @map("updated_at") @db.Timestamp(0)
  
  user        User     @relation(fields: [userId], references: [id])
  
  @@map("posts")
  @@index([userId])
}
```

### Naming Conventions

- Model names: PascalCase singular (User, Post)
- Field names: camelCase
- Use @map for DB column mapping
- Use @@map for table mapping

### Type Mappings

```prisma
// String types
email     String   @db.VarChar(255)      // Variable length
password  String   @db.Char(60)          // Fixed length for hash
content   String   @db.Text              // Long text

// Number types  
id        Int      @db.UnsignedInt       // Auto increment
count     Int      @db.TinyInt           // Small numbers
price     Decimal  @db.Decimal(10, 2)    // Money

// Date types
createdAt DateTime @db.DateTime          // Full timestamp
updatedAt DateTime @db.Timestamp(0)      // Auto-update timestamp
birthDate DateTime @db.Date              // Date only

// Boolean
enabled   Boolean  @default(true)
```

### View Models

```prisma
// For database views (read-only)
model UserProfile {
  id         Int      @id
  email      String
  name       String
  avatarUrl  String?  @map("avatar_url")
  bio        String?
  
  @@map("v_user_profiles")
  @@ignore
}
```

### Seed Data

```javascript
// prisma/seed.js
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  // Create user
  const hashedPassword = await bcrypt.hash('password123', 10);
  
  await prisma.user.create({
    data: {
      email: 'admin@example.com',
      password: hashedPassword,
      name: 'Administrator',
      profile: {
        create: {
          bio: 'System Administrator',
        },
      },
    },
  });
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

### Schema Sync Process

1. sql-agent creates/modifies schema.sql
2. Update Prisma schema to match
3. Run `prisma db pull` to verify
4. NO `prisma migrate` commands
5. Use `prisma generate` for client

### Common Patterns

```prisma
// Soft delete pattern
deletedAt DateTime? @map("deleted_at") @db.DateTime

// Audit fields
createdBy Int? @map("created_by") @db.UnsignedInt
updatedBy Int? @map("updated_by") @db.UnsignedInt

// JSON fields
metadata Json? @db.Json
```

## Commands

```bash
# Pull DB schema (verify only)
yarn prisma db pull

# Generate Prisma Client
yarn prisma generate

# Run seed
yarn prisma db seed
```

## References

- Coordinate with sql agent for schema changes
- Coordinate with backend agent for model usage
- See CLAUDE.md for naming conventions