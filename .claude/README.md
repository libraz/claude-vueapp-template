# Claude Code Configuration

## Hooks Configuration

The following coding standards are automatically enforced:

### Code Quality Check (lint-check.sh)
- **ESLint**: Automatic check and fix with Airbnb rules
- **Prettier**: Automatic formatting
- **Vue Options API**: Warning when used (Composition API recommended)
- **OpenAPI Validation**: Automatic validation when spec files change

### File Naming Validation (validate-filename.sh)
- **General Files**: Enforced kebab-case (e.g., my-component.js)
- **Vue Components**: Enforced PascalCase (e.g., MyComponent.vue)
- **Test Files**: Recommended .test.js format

### New File Validation (validate-new-file.sh)
- **.env Files**: Creation prohibited (use config module)
- **TypeScript**: Creation prohibited (JavaScript only)
- **CommonJS**: Usage prohibited (ESM only)
- **Prisma Migrations**: Creation prohibited (use schema.sql)

### Command Logging (log-command.sh)
- **Bash Command History**: Records executed commands to `.claude/command.log`
- **Log Format**: `[timestamp] Bash: command`
- **Gitignored**: Log file is automatically excluded from Git

### Configuration Files

- `.claude/settings.json`: Claude Code configuration (permissions, hooks)
- `.claude/hooks/lint-check.sh`: Lint/format execution script
- `.claude/hooks/validate-filename.sh`: File naming validation script
- `.claude/hooks/validate-new-file.sh`: New file validation script
- `.claude/hooks/log-command.sh`: Command logging script
- `.claude/command.log`: Command execution history (gitignored)

### Notes

- ESLint and Prettier are only executed if configuration files (`.eslintrc.js`, `.prettierrc`) exist in the project
- Applies to JavaScript and Vue files
- If violations are found, error messages are displayed but file creation/editing continues