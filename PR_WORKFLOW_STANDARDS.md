# PR Workflow Standards

## Problem Statement
Multiple open PRs create merge conflicts, workflow confusion, and make it difficult to track what changes are in what state. This leads to:
- Complex merge conflicts when multiple PRs touch the same files
- Unclear dependency relationships between changes
- Difficulty in reviewing and testing changes in isolation
- Risk of losing track of important changes

## Solution: One-PR-at-a-Time Workflow

### Core Principle
**Only ONE pull request should be open at any given time.**

### Workflow Rules

#### 1. Pre-Work Checks (REQUIRED before starting new work)
Before starting any new work session:
```bash
# Run the preflight check
./bin/preflight-check

# Manual verification:
gh pr list --state open
# Should return ZERO open PRs or explicit approval to proceed
```

#### 2. Branch Management
- Use descriptive branch names: `issue-{number}`, `fix-{description}`, `feature-{description}`
- Always branch from latest `main`
- Delete branches after PR merge

#### 3. PR Lifecycle
1. **Create PR** only when work is complete and tested
2. **Request review** immediately after creation
3. **Merge promptly** after approval (same day preferred)
4. **Delete branch** immediately after merge
5. **Start next work** only after previous PR is merged

#### 4. Exception Handling
**Multiple PRs are ONLY allowed if:**
- PRs have zero file overlap (completely different areas)
- Explicit dependency is documented (PR B depends on PR A)
- Emergency hotfix required while feature work is in progress

### Emergency Protocol
If multiple PRs exist accidentally:
1. **STOP all new work immediately**
2. **Prioritize**: Identify the most critical PR
3. **Merge or close**: Get open PRs to zero as quickly as possible
4. **Document**: Why it happened and how to prevent it

## Implementation

### 1. Preflight Hooks
- Pre-commit hook to check for open PRs
- Pre-push hook to verify PR readiness
- Branch creation hook to ensure clean state

### 2. CLAUDE.md Requirements
- AI assistant must check for open PRs before creating new branches
- AI assistant must merge/close existing PRs before starting new work
- Exception: If user explicitly overrides with "ultrathink" directive

### 3. Automation
- GitHub Actions to auto-close stale PRs (7+ days old)
- Auto-delete merged branches
- PR template enforcing single-PR principle

## Benefits
- **Reduced conflicts**: No competing changes
- **Faster reviews**: Clear focus on single changeset
- **Better testing**: Isolated changes easier to validate
- **Cleaner history**: Linear development flow
- **Less cognitive load**: Team focuses on one change at a time

## Tools
- `./bin/preflight-check` - Verify clean state before work
- `gh pr list --state open` - Manual verification
- GitHub branch protection rules
- Automated cleanup scripts

---
**Remember**: One PR at a time keeps the codebase healthy and the team productive.