# Railway MCP Authentication Fix

## 🔴 The Problem
Railway MCP is failing with "Not logged in" errors because:
1. MCP uses Railway CLI commands under the hood
2. MCP runs in a separate context without access to your CLI login session
3. The token in application.yml (`7fbe3f08-b150-4c08-bce9-2fe7af8ef6b6`) is invalid/expired

## ✅ Solution: Generate New API Token

### Step 1: Generate Railway API Token
1. Go to Railway Dashboard: https://railway.com/account/tokens
2. Click "Create New Token"
3. Name it: "backstage-pass-mcp" (or similar)
4. Copy the generated token (starts with `rw_`)

### Step 2: Set Token for MCP
```bash
# Add to your shell profile (~/.zshrc or ~/.bashrc)
export RAILWAY_API_TOKEN="your-new-token-here"
export RAILWAY_TOKEN="your-new-token-here"

# Reload shell
source ~/.zshrc
```

### Step 3: Update application.yml
Replace the old token with your new one:
```yaml
RAILWAY_TOKEN: "your-new-token-here"
```

### Step 4: Test MCP Access
```bash
# Test with environment variable
RAILWAY_TOKEN="your-new-token" railway whoami

# If that works, MCP should work too
```

## 🔧 Alternative: Project-Specific Token

For better security, use a project-specific token:

1. Go to your project: https://railway.com/project/28165735-d967-4f47-adab-24e148584cec
2. Click Settings → Tokens
3. Create a project token for "production" environment
4. Use this token specifically for deployment automation

## 📝 Build Error Fix

Your build is also failing due to missing `.ruby-version` file:

```bash
# Create .ruby-version file
echo "3.3.0" > .ruby-version

# Update Dockerfile to match
# ARG RUBY_VERSION=3.3.0
```

## 🚀 Complete Fix Sequence

1. Generate new Railway API token from dashboard
2. Export token in environment: `export RAILWAY_TOKEN="new-token"`
3. Fix Ruby version: `echo "3.3.0" > .ruby-version`
4. Deploy: `railway up`

## Why CLI Works but MCP Doesn't

- **CLI**: Uses interactive login session stored in `~/.railway/config.json`
- **MCP**: Runs commands in isolated context, needs explicit token
- **Solution**: Provide token via environment variable that MCP can access

The token in `~/.railway/config.json` is a session token that expires and isn't meant for programmatic use. API tokens from the dashboard are long-lived and designed for automation.