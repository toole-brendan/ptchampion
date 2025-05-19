# Branch Protection Configuration Guide

This document outlines the recommended branch protection rules for the PT Champion repository. These settings should be configured manually by a repository administrator in the GitHub settings.

## Protected Branches

The following branches should be protected:
- `main` (production)
- `dev` (development)

## Branch Protection Rules for `main`

### Requirements:
1. **Require pull request reviews before merging**
   - Require at least 1 approval
   - Dismiss stale pull request approvals when new commits are pushed
   - Require review from Code Owners (CODEOWNERS file should be configured)

2. **Require status checks to pass before merging**
   - Require branches to be up to date before merging
   - Required status checks:
     - `test-migrations`
     - `go-test`
     - `node-test`
     - `android-test` (if applicable)
     - `ios-test` (if applicable)

3. **Require signed commits**

4. **Require linear history**

5. **Include administrators**

6. **Restrict who can push to matching branches**
   - Limit push access to repository administrators

## Branch Protection Rules for `dev`

### Requirements:
1. **Require pull request reviews before merging**
   - Require at least 1 approval

2. **Require status checks to pass before merging**
   - Require branches to be up to date before merging
   - Required status checks:
     - `test-migrations`
     - `go-test`
     - `node-test`

3. **Require linear history**

4. **Include administrators**

## Setting Up Branch Protection

1. Go to the repository on GitHub
2. Navigate to Settings > Branches
3. Under "Branch protection rules," click "Add rule"
4. Enter the branch name (e.g., `main` or `dev`)
5. Configure the rules as specified above
6. Click "Create" to apply the rules

## CODEOWNERS Setup

Create a `.github/CODEOWNERS` file to define which teams or individuals are responsible for code review in specific parts of the repository.

Example structure:
```
# Global owners (fallback reviewers)
*       @organization/admin-team

# Backend code
/cmd/   @organization/backend-team
/internal/ @organization/backend-team
/pkg/   @organization/backend-team

# Web frontend
/web/   @organization/web-team

# iOS app
/ios/   @organization/ios-team  

# Android app
/android/ @organization/android-team
```

Note that these code owners must be added as collaborators or team members in the repository with appropriate permissions. 