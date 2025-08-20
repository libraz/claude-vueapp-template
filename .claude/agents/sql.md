---
name: sql
description: Designs and manages database schemas, views, and indexes following Rails naming conventions. Creates views for complex queries to simplify server-side data access.
tools: Read, Write, Edit, MultiEdit, Glob, Grep
---

# SQL Schema Agent

## Responsibilities
- Design database schemas
- Create/optimize views
- Manage SQL files (tables/ and views/ directories)
- NO Prisma migrations
- Schema is built dynamically via build-schema.sh

## Standards

### File Structure
```
sql/
├── build-schema.sh    # Script to dynamically build complete schema
├── tables/            # Table definitions (one file per table)
│   ├── users.sql      # NO numeric prefixes
│   ├── user_roles.sql
│   └── ...
├── views/             # View definitions
│   ├── v_active_users.sql
│   └── ...
└── samples/           # Sample data (optional)
    └── users_sample.sql
```

### File Organization Rules
- **ALWAYS split tables into separate files** - one table per file
- **NO numeric prefixes** - files are loaded alphabetically
- Group related functionality (tables/, views/, samples/)
- build-schema.sh dynamically combines all files with proper FK handling
- Run `./build-schema.sh | mysql -u user -p dbname` to apply schema

### Naming (Rails Convention)
- All snake_case
- Tables: plural (`users`, `products`)
- Columns: singular (`user_id`, `product_name`)
- Views: `v_` prefix (`v_users`, `v_user_profiles`)
- Foreign keys: `{table_singular}_id` (`user_id`)

### Column Naming
- **Dates (DATE type)**: MUST use `_on` suffix (`published_on`, `started_on`, `due_on`)
  - WRONG: `due_date`, `start_date`, `end_date`
  - CORRECT: `due_on`, `started_on`, `ended_on`
- **Timestamps (DATETIME/TIMESTAMP type)**: MUST use `_at` suffix (`created_at`, `updated_at`)
- Booleans: `is_xxx` (except `enabled`)
- NO `disabled`, use `enabled` instead

### Required Columns
```sql
id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
created_at DATETIME NOT NULL,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```
**Important**: Only ONE TIMESTAMP column per table - use `updated_at` with TIMESTAMP type, `created_at` with DATETIME type

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
- **IMPORTANT**: Do NOT use `BIGINT` without explicit justification - use `INT UNSIGNED` for IDs

### Views

#### View Design Philosophy
Views serve as the **primary data access layer** for the backend, encapsulating complex queries and business logic to simplify server-side development. The backend should interact with views rather than directly querying tables whenever possible.

#### Core Principles
1. **Encapsulation**: Views hide complex JOINs, aggregations, and business logic
2. **Consistency**: Provide consistent data structures across the application
3. **Performance**: Pre-optimize common query patterns
4. **Security**: Control data exposure through view definitions
5. **Maintainability**: Centralize query logic for easier updates

#### View Categories

##### 1. Entity Views (`v_[entity]`)
Basic views that enhance single entities with computed fields or light joins:
```sql
CREATE VIEW v_users AS
SELECT 
    u.*,
    COALESCE(p.display_name, u.name) AS display_name,
    CASE 
        WHEN u.last_login_at > DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 
        ELSE 0 
    END AS is_recently_active
FROM users u
LEFT JOIN profiles p ON u.id = p.user_id
WHERE u.enabled = 1;
```

##### 2. Relationship Views (`v_[entity1]_[entity2]`)
Views that represent many-to-many relationships or complex associations:
```sql
CREATE VIEW v_user_projects AS
SELECT 
    up.user_id,
    up.project_id,
    u.name AS user_name,
    p.name AS project_name,
    up.role,
    up.joined_at
FROM user_projects up
INNER JOIN users u ON up.user_id = u.id
INNER JOIN projects p ON up.project_id = p.id
WHERE u.enabled = 1 AND p.enabled = 1;
```

##### 3. Aggregation Views (`v_[entity]_stats`)
Views that pre-calculate statistics and aggregations:
```sql
CREATE VIEW v_project_stats AS
SELECT 
    p.id AS project_id,
    p.name AS project_name,
    COUNT(DISTINCT up.user_id) AS member_count,
    COUNT(DISTINCT t.id) AS task_count,
    SUM(CASE WHEN t.status = 'completed' THEN 1 ELSE 0 END) AS completed_task_count,
    MAX(t.updated_at) AS last_activity_at
FROM projects p
LEFT JOIN user_projects up ON p.id = up.project_id
LEFT JOIN tasks t ON p.id = t.project_id
WHERE p.enabled = 1
GROUP BY p.id, p.name;
```

##### 4. List Views (`v_[entity]_list`)
Optimized views for listing/searching with essential fields only:
```sql
CREATE VIEW v_task_list AS
SELECT 
    t.id,
    t.title,
    t.status,
    t.priority,
    t.due_on,
    u.name AS assignee_name,
    p.name AS project_name,
    t.updated_at
FROM tasks t
LEFT JOIN users u ON t.assignee_id = u.id
LEFT JOIN projects p ON t.project_id = p.id
WHERE t.enabled = 1
ORDER BY t.priority DESC, t.due_on ASC;
```

##### 5. Detail Views (`v_[entity]_detail`)
Comprehensive views for single record display with all related data:
```sql
CREATE VIEW v_task_detail AS
SELECT 
    t.*,
    u.name AS assignee_name,
    u.email AS assignee_email,
    p.name AS project_name,
    p.description AS project_description,
    c.name AS creator_name,
    cat.name AS category_name,
    (SELECT COUNT(*) FROM task_comments WHERE task_id = t.id) AS comment_count,
    (SELECT COUNT(*) FROM task_attachments WHERE task_id = t.id) AS attachment_count
FROM tasks t
LEFT JOIN users u ON t.assignee_id = u.id
LEFT JOIN users c ON t.created_by = c.id
LEFT JOIN projects p ON t.project_id = p.id
LEFT JOIN categories cat ON t.category_id = cat.id
WHERE t.enabled = 1;
```

#### View Naming Conventions
- `v_[entity]` - Basic entity view
- `v_[entity]_list` - Optimized for lists/grids
- `v_[entity]_detail` - Full detail view
- `v_[entity]_stats` - Aggregated statistics
- `v_[entity1]_[entity2]` - Relationship views
- `v_[entity]_[status]` - Filtered views (e.g., `v_tasks_pending`)

#### Best Practices
1. **Always include enabled checks** in WHERE clauses
2. **Check enabled status on ALL joined tables** that have enabled columns
3. **Use COALESCE** for default values
4. **Include computed fields** that the backend would otherwise calculate
5. **Optimize for common access patterns** identified during development
6. **Document complex logic** with comments in the view definition
7. **Version view changes** carefully as they impact the backend directly
8. **Consider indexes** on underlying tables for view performance
9. **Use consistent field naming** across similar views

#### Handling Enabled Status in JOINs
When creating views, it's crucial to properly filter ALL tables by their enabled status:

##### Tables with enabled columns:
- `users`
- `user_groups`
- `user_contracts`
- `elearnings`
- `surveys`
- `schedules`
- `work_items`
- `attendance_request_statuses`

##### JOIN Patterns:
1. **INNER JOIN** - Add to WHERE clause:
```sql
SELECT ...
FROM main_table m
INNER JOIN users u ON m.user_id = u.id
WHERE m.enabled = TRUE
  AND u.enabled = TRUE  -- 重要：結合先のenabledも確認
```

2. **LEFT JOIN** - Add to JOIN condition:
```sql
SELECT ...
FROM main_table m
LEFT JOIN users u ON m.user_id = u.id AND u.enabled = TRUE  -- JOIN条件に追加
WHERE m.enabled = TRUE
```

3. **Subqueries** - Filter within subquery:
```sql
SELECT ...,
  (SELECT name FROM users WHERE id = m.user_id AND enabled = TRUE) AS user_name
FROM main_table m
WHERE m.enabled = TRUE
```

##### Common Mistakes to Avoid:
- ❌ Forgetting to check enabled on joined users table
- ❌ Not filtering user_groups when joining through relationships
- ❌ Missing enabled check on user_contracts in attendance views
- ❌ Inconsistent handling between different views

##### Example - Complete filtering:
```sql
CREATE VIEW v_projects AS
SELECT 
    p.*,
    u.name AS created_by_name,
    ug.name AS group_name,
    COUNT(DISTINCT t.id) AS task_count
FROM projects p
LEFT JOIN users u ON p.created_by = u.id AND u.enabled = TRUE
LEFT JOIN user_groups ug ON p.group_id = ug.id AND ug.enabled = TRUE
LEFT JOIN tasks t ON p.id = t.project_id AND t.enabled = TRUE
WHERE p.enabled = TRUE
GROUP BY p.id;
```

#### Example: Complete View Set for Tasks
```sql
-- List view for task grids
CREATE VIEW v_task_list AS ...

-- Detail view for single task display
CREATE VIEW v_task_detail AS ...

-- Stats view for dashboards
CREATE VIEW v_task_stats AS ...

-- Filtered views for common queries
CREATE VIEW v_tasks_overdue AS
SELECT * FROM v_task_list 
WHERE due_on < CURDATE() AND status != 'completed';

CREATE VIEW v_tasks_by_user AS
SELECT assignee_id, assignee_name, COUNT(*) as task_count
FROM v_task_list
GROUP BY assignee_id, assignee_name;
```

### Constraints
- Always add foreign key constraints
- Explicit ON DELETE/UPDATE behavior

### Table File Template
```sql
-- ====================================
-- Table Name
-- Table description in Japanese
-- ====================================
CREATE TABLE table_name (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'ID',
    -- Business columns
    column_name TYPE COMMENT 'Description in Japanese',
    -- Standard columns
    sort_weight INT NOT NULL DEFAULT 0 COMMENT '表示順',
    notes TEXT DEFAULT NULL COMMENT '管理者用メモ',
    enabled BOOLEAN NOT NULL DEFAULT TRUE COMMENT '有効/無効フラグ',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新日時',
    created_at DATETIME NOT NULL COMMENT '作成日時',
    -- Indexes and constraints
    KEY idx_table_name_column (column_name),
    CONSTRAINT fk_table_name_ref FOREIGN KEY (ref_id) REFERENCES ref_table(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Table description in Japanese';
```

## References
- See CLAUDE.md for project specs
- Coordinate with backend agent for Prisma mapping
- Coordinate with prisma agent for schema.prisma @map configuration

## Schema Management
- **NO manual schema.sql file** - use build-schema.sh instead
- build-schema.sh automatically:
  - Disables foreign key checks (SET FOREIGN_KEY_CHECKS = 0)
  - Loads all tables/*.sql files alphabetically
  - Re-enables foreign key checks
  - Loads all views/*.sql files
- To apply schema: `cd sql && ./build-schema.sh | mysql -u user -p dbname`
