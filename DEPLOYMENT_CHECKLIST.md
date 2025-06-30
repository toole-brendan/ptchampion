# PTChampion Production Deployment Checklist

## Problem Summary
Production site was serving stale cached content due to a service worker bug that cached JavaScript files too aggressively. The service worker's fetch handler had conditions in the wrong order, causing JS/CSS files to be served from cache instead of fetched fresh on updates.

## Fixes Applied

### 1. Service Worker Cache Fix (v8)
- **Fixed fetch handler order** in `/web/src/serviceWorker.ts`:
  - Moved JS/CSS fresh fetch logic BEFORE the general assets cache-first strategy
  - Removed root path `/` from APP_SHELL_ASSETS to ensure HTML is always fetched fresh
  - Bumped cache version to v8 to force service worker update

### 2. Build Process
- Compiled TypeScript service worker to JavaScript: `npx esbuild src/serviceWorker.ts --bundle --outfile=public/sw.js --platform=browser --target=es2020`
- Built production bundle: `npm run build`
- New files generated:
  - Service worker: `sw.js` (v8-CACHE-FIX)
  - Main bundle: `index-DkPIybI6.js`

### 3. Dashboard UI Fixes (Already in Code)
All dashboard display issues were already fixed in the code but weren't visible due to the caching issue:
- **Last Activity**: Shows proper exercise name and date in DDMONYYYY format
- **Average Run Time**: Displays in MM:SS format or "No runs"
- **Recent Activity**: Shows exercise-specific icons (push-up, pull-up, sit-up, run)
- **Run times**: Displays time instead of "0 reps" for running workouts

## Deployment Steps

1. **Deploy to Azure via GitHub Actions**:
   - Go to the [PTChampion GitHub Actions page](https://github.com/brendantoole/ptchampion/actions)
   - Click on "Deploy to Production" workflow
   - Click "Run workflow" button
   - Select options:
     - Deploy frontend: ✓ (checked)
     - Deploy backend: ✓ (checked if needed, but for this fix only frontend is required)
   - Click "Run workflow" to start deployment

2. **Verify Deployment**:
   - Open the production site in a new incognito/private window
   - Open browser Developer Tools > Console
   - Look for: `PT CHAMPION VERSION: 2024-06-30-v8-CACHE-FIX`
   - Check Network tab to verify new files are loaded:
     - `sw.js` should show v8
     - Main JS file should be `index-DkPIybI6.js` (not the old `index-D6ceKvqi.js`)

3. **Clear Cache for Existing Users** (if needed):
   - Users should automatically get the update when they visit the site
   - If any users are stuck, direct them to: `/clear-cache.html`
   - This page unregisters the service worker and clears all caches

4. **Monitor Service Worker**:
   - In Console, you should see:
     - `[Service Worker] Installing`
     - `[Service Worker] Removing cache pt-champion-static-v7-DASHBOARD-FIX` (and other v7 caches)
     - `[Service Worker] Activating`
     - `[Service Worker] Reloading client`

5. **Verify Dashboard Fixes**:
   - Check that "LAST ACTIVITY" shows actual activity (not "None")
   - Verify "AVERAGE RUN TIME" shows time in MM:SS format
   - Confirm Recent Activity shows proper exercise icons
   - Check that dates are in DDMONYYYY format (e.g., "30JUN2025")
   - Verify runs show time (e.g., "15:30") not "0 reps"

## Important Notes

- The service worker will automatically clear ALL old caches on activation
- HTML pages are always fetched fresh (never cached)
- JS/CSS files in `/assets/` are always fetched fresh to ensure updates
- Other static assets (images, fonts) use cache-first for performance

## Rollback Plan

If issues occur after deployment:
1. Revert the service worker changes in `serviceWorker.ts`
2. Bump version to v9
3. Rebuild and redeploy
4. The new service worker will automatically take over

## Future Prevention

To prevent similar issues:
1. Always test service worker changes thoroughly
2. Include version bumps in service worker when making critical changes
3. Consider adding automated tests for caching behavior
4. Monitor production console logs after deployments