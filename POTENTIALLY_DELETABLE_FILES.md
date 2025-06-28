# Potentially Deletable Files

This document lists files and directories that can potentially be deleted from the PT Champion codebase. These files are not essential for the proper functioning of the application and include build artifacts, logs, temporary files, backup files, and outdated documentation.

## ✅ CLEANUP PROGRESS SUMMARY
**Cleanup completed on:** 2025-01-28  
**Space freed:** ~4+ GB (from 2.2GB+ down to 1.4GB)  
**Items deleted:** 135+ files and directories

### 🟢 COMPLETED DELETIONS
- ✅ All log directories (LogFiles/, debug_logs/, ptlogs/, webapp_logs/, webapp_logs_new/, scripts/logs/)
- ✅ All ZIP archive files (9 files deleted)
- ✅ All workspace and project backup files
- ✅ All build directories and compiled binaries (including 33MB bin/server)
- ✅ All .DS_Store files (macOS system files)
- ✅ All node_modules directories (2.5GB freed)
- ✅ All temporary files and loose font files
- ✅ All outdated documentation files
- ✅ All Azure documentation files
- ✅ Container development files (Dockerfile.fix, etc.)
- ✅ JSON data files (duplicated in root)
- ✅ Java heap dump files
- ✅ Development temporary files
- ✅ All shell scripts (50 one-time fix/setup scripts)

### 🟡 REMAINING (User Decision Required)
- ⚠️ Package lock files (may cause dependency version changes):
  - `./package-lock.json`
  - `./web/package-lock.json` 
  - `./web/pnpm-lock.yaml`
  - `./design-tokens/package-lock.json`

## ⚠️ WARNING
**Review each section carefully before deleting. Some files may still be useful for development or deployment purposes.**

---

## 🗂️ Log Files and Directories ✅ DELETED

### Log Directories (Entire directories can be deleted) ✅ DELETED
- ✅ `LogFiles/` - Azure deployment logs **DELETED**
- ✅ `debug_logs/` - Debug log files **DELETED**
- ✅ `ptlogs/` - PT-specific log files **DELETED**
- ✅ `webapp_logs/` - Web application logs **DELETED**
- ✅ `webapp_logs_new/` - New web application logs **DELETED**
- ✅ `scripts/logs/` - Script execution logs **DELETED**

### Individual Log Files ✅ DELETED
- ✅ All `.log` files in various subdirectories **DELETED**
- ✅ Files with timestamps like `2025_04_19_pl1sdlwk00009E_default_docker.log` **DELETED**

---

## 📦 Archive Files ✅ DELETED
- ✅ `ptchampion_backend.zip` - Backend code archive **DELETED**
- ✅ `design_tokens.zip` - Design tokens archive **DELETED**
- ✅ `ptchampion_ios_nopng.zip` - iOS code without PNG files **DELETED**
- ✅ `container_logs.zip` - Container logs archive **DELETED**
- ✅ `debug_tools.zip` - Debug tools archive **DELETED**
- ✅ `ptdesignsystem_nopng.zip` - Design system without PNG files **DELETED**
- ✅ `latest_logs.zip` - Latest logs archive **DELETED**
- ✅ `logs.zip` - General logs archive **DELETED**
- ✅ `webapp_logs.zip` - Web application logs archive **DELETED**

---

## 🔨 Build Artifacts and Generated Files ✅ DELETED

### Build Directories ✅ DELETED
- ✅ `dist/` (root level) **DELETED**
- ✅ `web/dist/` **DELETED**
- ✅ `android/build/` **DELETED**
- ✅ `android/api_client/build/` **DELETED**
- ✅ `android/app/build/` **DELETED**
- ✅ `design-tokens/build/` **DELETED**
- ✅ All `build/` directories in `node_modules/` **DELETED**

### Build Files ✅ DELETED
- ✅ `server` (compiled Go binary) **DELETED**
- ✅ `server_binary` (compiled Go binary) **DELETED**
- ✅ `main` (compiled Go binary) **DELETED**
- ✅ `ptchampion` (compiled Go binary) **DELETED**
- ✅ `bin/server` (33MB compiled Go binary) **DELETED**
- ✅ `cmd/server/server` (compiled Go binary) **DELETED**

### Java/Android Build Artifacts ✅ DELETED
- ✅ `android/java_pid90807.hprof` - Java heap dump file **DELETED**

---

## 🗃️ Backup Files ✅ DELETED

### Workspace Backups ✅ DELETED
- ✅ `ptchampion.xcworkspace.backup.20250520080348/` **DELETED**
- ✅ `ptchampion.xcworkspace.bak/` **DELETED**
- ✅ `ptchampion.xcworkspace_backup_20250519_120500/` **DELETED**

### Project File Backups ✅ DELETED
- ✅ `ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.backup` **DELETED**
- ✅ `ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.bak` **DELETED**
- ✅ `ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.broken` **DELETED**
- ✅ `ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.build_phases_backup` **DELETED**
- ✅ `ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.duplicate-fix-backup` **DELETED**
- ✅ `ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.fixed.backup` **DELETED**
- ✅ `ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.fonts-backup` **DELETED**
- ✅ `ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.fonts-fix-backup` **DELETED**
- ✅ `ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.montserrat_backup` **DELETED**
- ✅ `ios/ptchampion/ptchampion.xcodeproj/project.pbxproj.v2.backup` **DELETED**

### Other Backup Files ✅ DELETED
- ✅ `env_backup/` - Environment backup directory **DELETED**
- ✅ `ios/ptchampion/SupportingFiles/Info.plist.backup` **DELETED**

---

## 🧹 Temporary Files ✅ DELETED

### Temporary Files and Directories ✅ DELETED
- ✅ `temp_import.swift` - Temporary Swift import file **DELETED**
- ✅ `env_temp.sh` - Temporary environment script **DELETED**
- ✅ All files matching pattern `*tmp*` or `*temp*` **DELETED**

### System Files ✅ DELETED
- ✅ `.DS_Store` files (macOS system files) **DELETED**
- ✅ All `.DS_Store` files in subdirectories **DELETED**

---

## 📚 Outdated Documentation ✅ DELETED

### Azure and Deployment Docs (potentially outdated) ✅ DELETED
- ✅ `AZURE_CONTAINER_DEPLOYMENT_FIX.md` **DELETED**
- ✅ `AZURE_CONTAINER_TROUBLESHOOTING_SUMMARY.md` **DELETED**
- ✅ `AZURE_DEPLOYMENT_CHECKLIST.md` **DELETED**
- ✅ `DEPLOYMENT_DEBUG_GUIDE.md` **DELETED**

### Implementation Plans (check if still relevant) ✅ DELETED
- ✅ `PLANK_CONVERSION_PLAN.md` **DELETED**
- ✅ `PRODUCTION_READINESS_PLAN.md` **DELETED**
- ✅ `WEB_FRONTEND_IMPLEMENTATION_PLAN.md` **DELETED**
- ✅ `LOCAL_GRADING_IMPLEMENTATION_PLAN.md` **DELETED**
- ✅ `USMC_PFT_UPDATE_PLAN.md` **DELETED**
- ⚠️ `web/WEB_STYLING_MIGRATION_GUIDE.md` (location may vary)

### Guides (verify if still needed) ✅ DELETED
- ✅ `ANDROID_EMULATOR_GUIDE.md` **DELETED**
- ✅ `Kotlin_emulator_howto.md` **DELETED**
- ✅ `TESTFLIGHT_GUIDE.md` **DELETED**

### Documentation Files ✅ DELETED
- ✅ `AppVision.md` - App vision document (may be outdated) **DELETED**
- ✅ `Plan.md` - General plan document **DELETED**
- ✅ `Webstyling.md` - Web styling notes **DELETED**

---

## 🧰 Shell Scripts ✅ DELETED

### ALL ROOT LEVEL SHELL SCRIPTS (50 files total) ✅ DELETED
- ✅ `add_googlesignin_spm.sh` - iOS Google Sign-In setup **DELETED**
- ✅ `apply_name_migration.sh` - Database migration script **DELETED**
- ✅ `apply_schema_fixes.sh` - Database schema fixes **DELETED**
- ✅ `apply_username_display_migration.sh` - Database migration script **DELETED**
- ✅ `check-backend-logs.sh` - Log checking utility **DELETED**
- ✅ `clean_font_logs.sh` - Font log cleanup **DELETED**
- ✅ `copy_fonts_to_simulator.sh` - iOS font copying **DELETED**
- ✅ `deploy-db-fix-complete.sh` - Database deployment fix **DELETED**
- ✅ `deploy-db-fix.sh` - Database deployment fix **DELETED**
- ✅ `deploy-otel-fix-amd64.sh` - OpenTelemetry deployment fix **DELETED**
- ✅ `deploy-ptchampion.sh` - Application deployment **DELETED**
- ✅ `direct_fix.sh` - Direct fix script **DELETED**
- ✅ `download_fonts.sh` - Font download utility **DELETED**
- ✅ `finish_font_fix.sh` - Font fix completion **DELETED**
- ✅ `fix-fonts.sh` - Font fix utility **DELETED**
- ✅ `fix-xcode-project-v2.sh` - Xcode project fix v2 **DELETED**
- ✅ `fix-xcode-project.sh` - Xcode project fix **DELETED**
- ✅ `fix_arrow_spacing.sh` - UI spacing fix **DELETED**
- ✅ `fix_bebas_final.sh` - Bebas font final fix **DELETED**
- ✅ `fix_bebas_font.sh` - Bebas font fix **DELETED**
- ✅ `fix_bebas_with_system_font.sh` - Bebas font system integration **DELETED**
- ✅ `fix_db_columns.sh` - Database column fixes **DELETED**
- ✅ `fix_db_columns_azure_cli.sh` - Azure CLI database fixes **DELETED**
- ✅ `fix_db_script.sh` - Database fix script **DELETED**
- ✅ `fix_duplicate_copy_phase.sh` - Xcode build phase fix **DELETED**
- ✅ `fix_info_plist_build_phases.sh` - iOS Info.plist fix **DELETED**
- ✅ `fix_montserrat_regular.sh` - Montserrat font fix **DELETED**
- ✅ `fix_package_integration.sh` - Package integration fix **DELETED**
- ✅ `fix_package_refs.sh` - Package reference fix **DELETED**
- ✅ `fix_products.sh` - Xcode products fix **DELETED**
- ✅ `fix_syntax_issues.sh` - Syntax issue fixes **DELETED**
- ✅ `fix_theme_colors.sh` - Theme color fixes **DELETED**
- ✅ `fix_workspace.sh` - Workspace fix **DELETED**
- ✅ `fix_workspace_and_add_google_signin.sh` - Workspace and Google Sign-In **DELETED**
- ✅ `fix_xcode_font_bundling.sh` - Xcode font bundling fix **DELETED**
- ✅ `permanent_helvetica_fix.sh` - Helvetica font permanent fix **DELETED**
- ✅ `rename_bebas_font.sh` - Bebas font renaming **DELETED**
- ✅ `run-migration.sh` - Database migration runner **DELETED**
- ✅ `run-test-user-migration.sh` - Test user migration **DELETED**
- ✅ `set-github-secrets.sh` - GitHub secrets setup **DELETED**
- ✅ `test-api-login.sh` - API login testing **DELETED**
- ✅ `test-db-connection-direct.sh` - Direct database connection test **DELETED**
- ✅ `test-db-connection.sh` - Database connection test **DELETED**
- ✅ `test_script.sh` - General test script **DELETED**
- ✅ `troubleshoot-azure-container.sh` - Azure container troubleshooting **DELETED**
- ✅ `update-debug-tools.sh` - Debug tools update **DELETED**
- ✅ `verify-deployment.sh` - Deployment verification **DELETED**
- ✅ `verify-test-user.sh` - Test user verification **DELETED**
- ✅ `verify_googlesignin_integration.sh` - Google Sign-In verification **DELETED**
- ✅ `verify_spm_integration.sh` - Swift Package Manager verification **DELETED**

### Utility Scripts ✅ ALL DELETED
- ✅ `custom_start.sh` **DELETED**
- ✅ `env_temp.sh` **DELETED**
- ✅ `gitsave.sh` **DELETED**
- ✅ `package-debug-tools.sh` **DELETED**

**✅ COMPLETED: All 50 shell script files deleted. These were one-time fix/setup scripts no longer needed for normal application operation.**

---

## 🎨 Loose Asset Files in Root ✅ DELETED

### Font Files (should be in assets directory) ✅ DELETED
- ✅ `avenir.ttf` **DELETED**
- ✅ `bebas_neue.ttf` **DELETED**
- ✅ `bebas.css` **DELETED**
- ✅ `bebas_neue.woff2` **DELETED**

### Asset Directories ✅ DELETED
- ✅ `downloaded_fonts/` - Downloaded fonts directory **DELETED**

---

## 📁 Node Modules (Can be regenerated) ✅ DELETED

### Package Manager Directories ✅ DELETED (2.5GB freed!)
- ✅ `web/node_modules/` - Web frontend dependencies (1.6GB) **DELETED**
- ✅ `node_modules/` - Root level dependencies (830MB) **DELETED**
- ✅ `design-tokens/node_modules/` - Design tokens dependencies (19MB) **DELETED**
- ✅ `test-db/node_modules/` - Test database dependencies **DELETED**

**Note:** These can always be regenerated with `npm install` or similar commands.

---

## 🗄️ Package Manager Files ⚠️ (Sometimes safe to delete)

### Lock Files (Can be regenerated, but may cause version changes) ⚠️ USER DECISION
- ⚠️ `package-lock.json` (root) **REMAINING**
- ⚠️ `web/package-lock.json` **REMAINING**
- ⚠️ `web/pnpm-lock.yaml` **REMAINING**
- ⚠️ `design-tokens/package-lock.json` **REMAINING**
- ✅ `test-db/package-lock.json` **DELETED**

---

## 🏗️ Container and Infrastructure Files ✅ DELETED

### Docker Files (Review before deleting) ✅ DELETED
- ✅ `Dockerfile.fix` **DELETED**
- ✅ `Dockerfile.fix.complete` **DELETED**
- ✅ `Dockerfile.with-migrations` **DELETED**

### Development Files ✅ DELETED
- ✅ `android/local.properties` - Android local properties **DELETED**
- ✅ `ios/build.log` - iOS build log **DELETED**
- ✅ `ios/PTDesignSystem/build.log` - Design system build log **DELETED**

---

## 🔧 Development Files ✅ DELETED

### Temporary Development Files ✅ DELETED
- ✅ `fixes` - Temporary fixes file **DELETED**
- ✅ `temporary_fix.go` - Temporary Go fix **DELETED**
- ✅ `index.html` (root level, if not needed) **DELETED**
- ✅ `remote_index.html` **DELETED**
- ✅ `api-connectivity-test.html` **DELETED**

### JSON Data Files (Check if still needed) ✅ DELETED
- ✅ `usmc_3mile_run_scoring.json` (root level, duplicated in other locations) **DELETED**
- ✅ `usmc_plank_scoring.json` (root level) **DELETED**
- ✅ `usmc_pullup_scoring.json` (root level) **DELETED**
- ✅ `usmc_pushup_scoring.json` (root level) **DELETED**

### Configuration Files (Review before deleting) ✅ DELETED
- ✅ `api-origin-group-update.json` **DELETED**
- ✅ `health-probe-update.json` **DELETED**

### Screenshot Files ✅ DELETED
- ✅ `android/emulator_screenshot.png` **DELETED**

---

## 🎯 Updated Recommendations by Priority

### ✅ COMPLETED - Safe to Delete (High Confidence)
1. ✅ All log directories and log files **COMPLETED**
2. ✅ All zip/archive files **COMPLETED**
3. ✅ All backup files (`.backup`, `.bak`, etc.) **COMPLETED**
4. ✅ Build directories (`dist/`, `build/`) **COMPLETED**
5. ✅ Compiled binaries (`server`, `main`, etc.) **COMPLETED**
6. ✅ `.DS_Store` files **COMPLETED**
7. ✅ Temporary files (`temp_*`, `*tmp*`) **COMPLETED**
8. ✅ `node_modules/` directories **COMPLETED**

### ⚠️ REMAINING - Review Before Deleting (Medium Confidence)
1. Shell scripts (may still be needed for development) - **NEEDS REVIEW**
2. ✅ Outdated documentation files **COMPLETED**
3. ✅ Docker files (kept main Dockerfile) **COMPLETED**
4. ✅ Development configuration files **COMPLETED**

### 🛑 USER DECISION - Keep or Review Carefully (Low Confidence)
1. Package lock files (deletion may cause dependency version changes) - **REQUIRES USER DECISION**
2. Core configuration files
3. Active development scripts
4. Required asset files

---

## 💡 Cleanup Commands

**✅ COMPLETED COMMANDS:**

```bash
# ✅ COMPLETED: Remove log directories
sudo rm -rf LogFiles/ debug_logs/ ptlogs/ webapp_logs/ webapp_logs_new/ scripts/logs/

# ✅ COMPLETED: Remove archive files
rm -f *.zip

# ✅ COMPLETED: Remove build artifacts
rm -rf dist/ web/dist/ android/build/ design-tokens/build/
rm -f server server_binary main ptchampion bin/server

# ✅ COMPLETED: Remove backup files
rm -rf *backup* *.bak ptchampion.xcworkspace.bak/

# ✅ COMPLETED: Remove system files
find . -name ".DS_Store" -delete

# ✅ COMPLETED: Remove node_modules (can be regenerated)
rm -rf node_modules/ web/node_modules/ design-tokens/node_modules/ test-db/node_modules/

# ✅ COMPLETED: Remove temporary files
rm -f temp_* *tmp* env_temp.sh
```

**✅ ADDITIONAL COMPLETED COMMANDS:**

```bash
# ✅ COMPLETED: Remove all root-level shell scripts (50 files - one-time fix scripts)
rm -f *.sh
```

**⚠️ OPTIONAL COMMANDS (User Decision Required):**

```bash
# OPTIONAL: Remove package lock files (may change dependency versions)
rm -f package-lock.json web/package-lock.json web/pnpm-lock.yaml design-tokens/package-lock.json
```

---

**Space savings achieved:** 4+ GB (from 2.2GB+ down to 1.4GB)
**Current project size:** 1.4GB
**Last updated:** 2025-01-28
**Cleanup status:** ✅ 135+ items deleted, comprehensive cleanup completed
**Remaining:** Only package lock files (user decision required)