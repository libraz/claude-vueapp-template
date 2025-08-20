---
name: openapi
description: Creates and manages OpenAPI specifications, defines API endpoints, schemas, and validation rules for express-openapi-validator
tools: Read, Write, Edit, MultiEdit, Glob, Grep, Bash
---

# OpenAPI Specification Agent

## Responsibilities

- Create/manage OpenAPI spec files
- Define API endpoints and schemas
- Manage split specification files
- Build with @redocly/cli
- **Define all validation rules** - express-openapi-validator handles validation automatically

## Standards

### File Organization Rules

1. **Path Files**: Split by functional domain in `srv/openapi/paths/`
   - Each file contains related endpoints grouped by business function
   - Use $ref to reference from main index.yaml
   - Follow naming: kebab-case for multi-word domains

2. **Schema Files**: Split by domain in `srv/openapi/components/schemas/`
   - Mirror path file organization  
   - Common/shared schemas in `common.yaml`
   - Domain-specific schemas in respective files

3. **Reference Patterns**:
   ```yaml
   # In index.yaml - reference path files
   /api/v1/auth/login:
     $ref: './paths/auth.yaml#/~1api~1v1~1auth~1login'
   
   # In components/schemas.yaml - aggregate schema files
   User:
     $ref: './schemas/users.yaml#/User'
   ```

### File Structure

- `srv/openapi/index.yaml` - Main definitions with system endpoints
- `srv/openapi/paths/` - Path definitions by business function
  - Split endpoints into logical groups (auth, user management, business domains, admin)
  - Use descriptive filenames with kebab-case
- `srv/openapi/components/` - Shared schemas
  - `schemas.yaml` - Main schema aggregator
  - `schemas/` - Individual schema files by domain
    - Mirror path organization for consistency
    - `common.yaml` - Common/shared schemas across domains
- `srv/openapi/dist/` - Built output

### Design Rules

1. **Reusable Definitions**
   - Common schemas in `components/schemas`
   - Use `$ref` for reuse
   - `readOnly` for output-only fields
   - **NO `writeOnly`** (express-openapi-validator limitation)

2. **Naming**
   - Paths: snake_case (`/api/v1/user_profile`)
   - Schemas: PascalCase (`UserProfile`)
   - Properties: camelCase (`userId`)

3. **Status Code Rules**
   - **200 OK**: Success with response data (no `success: true` wrapper)
   - **201 Created**: Resource creation success
   - **204 No Content**: Success without response data (default for DELETE operations)
   - **400 Bad Request**: Validation errors
   - **401 Unauthorized**: Authentication required
   - **403 Forbidden**: Access denied
   - **404 Not Found**: Resource not found or disabled in datastore
   - **409 Conflict**: Resource conflicts

4. **HTTP Method Rules**
   - **PUT**: Full resource update (all fields required)
   - **PATCH**: Partial resource update (specific fields only) - **use as default**
   - Prefer PATCH for most update operations to allow flexible field updates
   - **PATCH Body Validation**: Request body must contain at least one property
     ```yaml
     requestBody:
       required: true
       content:
         application/json:
           schema:
             type: object
             minProperties: 1  # Prevents empty {} body
             properties:
               # field definitions...
     ```

5. **Response Format Rules**
   - **Success responses**: Return data directly (no wrapper objects)
   - **No `success: true` or `message` fields** in success responses
   - **Empty responses**: Use 204 No Content instead of empty objects
   - **List responses**: Use `{total: number, [resourceName]: []}` format
     - Example: `{total: 150, users: [{id: 1, name: "山田太郎"}, ...]}`
     - Do NOT include pagination params (`limit`, `offset`) in response
   - **Enabled/Disabled handling**: 
     - Normal responses exclude `enabled` field (only enabled data returned)
     - Normal POST requests exclude `enabled` field (defaults to enabled)
     - Disabled resources return 404 Not Found
     - Include `enabled` field only in admin APIs requiring explicit state management
   - **Error responses only**: Use ErrorResponse schema below

6. **Error Response Schema**
   ```yaml
   ErrorResponse:
     type: object
     required: [statusCode, code, errorCode, path, message]
     properties:
       statusCode: {type: integer}
       code: {type: string, description: "MD5 hash for error location"}
       errorCode: {type: string, description: "Machine-readable code (e.g., MISSING_EMAIL)"}
       path: {type: string}
       message: {type: string, description: "Error message in English only"}
       errors:
         type: array
         items:
           type: object
           properties:
             field: {type: string}
             errorCode: {type: string}
             message: {type: string, description: "Error message in English only"}
   ```
   
   **Note**: All error messages must be in English. Do not use Japanese in API error responses.

7. **Example Data Standards**
   - Use realistic, meaningful example data in OpenAPI specifications
   - For Japanese names: Use proper names like "山田太郎", "佐藤花子" instead of generic "ユーザー1"
   - For English names: Use proper names like "John Smith", "Sarah Johnson"
   - For emails: Use realistic domains like "yamada@example.com"
   - For addresses: Use realistic Japanese addresses or international examples
   - Avoid placeholder data like "test", "sample", "dummy"

8. **Data Type Standards**
   - **Integer Types**: Use `minimum: 1` for IDs (unsigned), `minimum: 0` for counts/quantities
   - **String Types**: Set `maxLength` based on DB VARCHAR limits:
     - `maxLength: 50` for system codes and identifiers
     - `maxLength: 100` for category names and department fields
     - `maxLength: 255` for titles, names, and general text content
     - `maxLength: 7` for color codes (#RRGGBB format)
   - **Email**: `maxLength: 255` with email format validation
   - **Pagination**: `limit`/`offset` query params
   - **Dates**: 
     - Fields ending with `At` (e.g., `createdAt`, `updatedAt`): UNIX timestamp (seconds) as integer
     - Fields ending with `On` (e.g., `startedOn`, `endedOn`): Date string in YYYY-MM-DD format
   - **Group paths by function** (organize by business domain)

### Build Process

```bash
yarn build:openapi      # Production build (no examples/descriptions)
yarn build:openapi:full # Development build (with examples/descriptions)
```

Combines split files → `srv/openapi/dist/openapi.yaml`

**Content Exclusion**:
- **Default behavior**: Removes both `example`/`examples` and `description` properties for production builds
- **Development builds**: Use `yarn build:openapi:full` to preserve all content for documentation
- **Fine-grained control**: Use environment variables:
  - `OPENAPI_KEEP_EXAMPLES=true` to preserve examples
  - `OPENAPI_KEEP_DESCRIPTIONS=true` to preserve descriptions
- Examples and descriptions are preserved in source files for development and documentation

### Validation Specifications

1. **All validation rules must be defined in OpenAPI schemas**
   - Field types, formats, and constraints
   - Required/optional fields
   - String patterns, lengths, and enums
   - Number ranges and formats
   - Array item types and constraints

2. **No manual validation in backend code**
   - express-openapi-validator automatically validates against OpenAPI spec
   - Backend receives pre-validated data
   - Validation errors automatically formatted as standardized error responses

3. **Common validation patterns**:
   ```yaml
   # Email validation
   email:
     type: string
     format: email
     maxLength: 255
   
   # Password validation
   password:
     type: string
     minLength: 8
     maxLength: 128
     pattern: '^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)'
   
   # Pagination parameters
   limit:
     type: integer
     minimum: 1
     maximum: 100
     default: 20
   
   # Date/time validation - timestamp fields
   createdAt:
     type: integer
     description: UNIX timestamp (seconds)
     readOnly: true
   
   # Date validation - date fields
   startedOn:
     type: string
     format: date
     pattern: '^\d{4}-\d{2}-\d{2}$'
     description: Date in YYYY-MM-DD format
     example: "2024-01-15"
   ```

## OpenAPI 3.0 Compatibility Rules

### Nullable Type Handling

1. **Basic nullable fields**: Always include `type` with `nullable`
   ```yaml
   # Correct
   fieldName:
     type: string
     nullable: true
     description: Optional field
   
   # Incorrect - will cause AJV validation error
   fieldName:
     nullable: true  # Missing type
     description: Optional field
   ```

2. **Nullable with $ref**: Cannot use `$ref` and `nullable` at same level in OpenAPI 3.0
   ```yaml
   # Incorrect - OpenAPI 3.0 doesn't allow this
   fieldName:
     $ref: '#/components/schemas/SomeSchema'
     nullable: true
   
   # Correct - use allOf with type
   fieldName:
     type: object  # Required when using nullable with allOf
     nullable: true
     description: Optional reference
     allOf:
       - $ref: '#/components/schemas/SomeSchema'
   ```

3. **Common validation errors**:
   - Error: `"nullable" cannot be used without "type"` - Add appropriate type
   - Error with `$ref` and `nullable` - Use `allOf` pattern with `type: object`

### Build and Validation

- After modifying OpenAPI specs, always rebuild:
  ```bash
  yarn build:openapi:full  # For development with examples/descriptions
  yarn build:openapi       # For production without examples/descriptions
  ```
- Restart backend server to apply changes
- Test with actual API calls to ensure validation works correctly

## References

- Main specs in CLAUDE.md
- Coordinate with backend agent for implementation
- **All validation defined here, not in backend code**
- **Always ensure OpenAPI 3.0 compatibility for express-openapi-validator**