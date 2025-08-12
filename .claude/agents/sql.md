---
name: sql
description: Designs and manages database schemas, views, and indexes following Rails naming conventions. Creates views for complex queries to simplify server-side data access.
tools: Read, Write, Edit, MultiEdit, Glob, Grep
---

# SQL Schema Agent

## Responsibilities
- Design database schemas
- Create/optimize views
- Manage cumulative schema.sql
- NO Prisma migrations

## Standards

### Files
- `sql/schema.sql` - Cumulative schema changes

### Naming (Rails Convention)
- All snake_case
- Tables: plural (`users`, `products`)
- Columns: singular (`user_id`, `product_name`)
- Views: `v_` prefix (`v_users`, `v_user_profiles`)
- Foreign keys: `{table_singular}_id` (`user_id`)

### Column Naming
- Dates: `_on` suffix (`published_on`)
- Timestamps: `_at` suffix (`created_at`)
- Booleans: `is_xxx` (except `enabled`)
- NO `disabled`, use `enabled` instead

### Required Columns
```sql
id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
created_at DATETIME NOT NULL,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

### Standard Columns
- `sort_weight` - for ordering
- `notes` - admin notes
- `enabled` - active flag

### Column Order
1. id
2. business columns
3. sort_weight
4. notes
5. enabled
6. updated_at
7. created_at

### Data Types
- ASCII only: `CHARACTER SET latin1` (email, password)
- Japanese/Unicode: `CHARACTER SET utf8mb4`
- Numbers: `UNSIGNED` by default
- Small data: Use `TINYINT` etc.
- Password: `CHAR(60) CHARACTER SET latin1` (for hash)

### Views
- Pre-define complex JOINs
- Server selects from views only
```sql
CREATE VIEW v_user_profiles AS
SELECT u.id, u.email, u.name, p.avatar_url, p.bio
FROM users u
LEFT JOIN profiles p ON u.id = p.user_id
WHERE u.enabled = 1;
```

### Constraints
- Always add foreign key constraints
- Explicit ON DELETE/UPDATE behavior

## References
- See CLAUDE.md for project specs
- Coordinate with backend agent for Prisma mapping