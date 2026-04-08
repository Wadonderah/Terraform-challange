#!/usr/bin/env bash
# ==============================================================================
# scripts/create-release.sh
#
# PURPOSE: Automate the release process for infrastructure modules.
# Creates semantic version tags and updates CHANGELOG.md.
#
# USAGE:
#   ./scripts/create-release.sh <version> <description>
#
# EXAMPLE:
#   ./scripts/create-release.sh v1.1.0 "Add monitoring and alerting"
# ==============================================================================

set -euo pipefail

VERSION="${1:-}"
DESCRIPTION="${2:-}"

if [[ -z "$VERSION" ]]; then
  echo "❌ Usage: $0 <version> <description>"
  echo ""
  echo "Examples:"
  echo "  $0 v1.0.0 'Initial release'"
  echo "  $0 v1.1.0 'Add CloudWatch monitoring'"
  echo "  $0 v1.0.1 'Fix security group rules'"
  exit 1
fi

# Validate version format
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ Invalid version format: $VERSION"
  echo "   Expected format: vX.Y.Z (e.g., v1.0.0)"
  exit 1
fi

if [[ -z "$DESCRIPTION" ]]; then
  echo "❌ Description is required"
  echo "   Provide a brief description of this release"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Creating Release: $VERSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Pre-flight checks
# ─────────────────────────────────────────────────────────────────────────────

echo "🔍 Running pre-flight checks..."

# Check if on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  echo "❌ Not on main branch (current: $CURRENT_BRANCH)"
  echo "   Releases must be created from main branch"
  exit 1
fi

# Check if working directory is clean
if [[ -n $(git status --porcelain) ]]; then
  echo "❌ Working directory is not clean"
  echo "   Commit or stash changes before creating a release"
  git status --short
  exit 1
fi

# Check if tag already exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "❌ Tag $VERSION already exists"
  echo "   Use a different version number"
  exit 1
fi

# Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin main

echo "✅ Pre-flight checks passed"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Update CHANGELOG.md
# ─────────────────────────────────────────────────────────────────────────────

echo "📝 Updating CHANGELOG.md..."

if [[ ! -f CHANGELOG.md ]]; then
  echo "❌ CHANGELOG.md not found"
  exit 1
fi

# Get current date
RELEASE_DATE=$(date +%Y-%m-%d)

# Extract version number without 'v' prefix
VERSION_NUM="${VERSION#v}"

# Create temporary file with updated changelog
cat > /tmp/changelog_update.txt << EOF

## [$VERSION_NUM] - $RELEASE_DATE

### Summary
$DESCRIPTION

### Changes
<!-- Add detailed changes here from git log -->
EOF

# Get commits since last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [[ -n "$LAST_TAG" ]]; then
  echo "" >> /tmp/changelog_update.txt
  echo "### Commits since $LAST_TAG:" >> /tmp/changelog_update.txt
  git log "$LAST_TAG"..HEAD --oneline --no-merges | sed 's/^/- /' >> /tmp/changelog_update.txt
fi

# Insert new version after [Unreleased] section
sed -i.bak '/## \[Unreleased\]/r /tmp/changelog_update.txt' CHANGELOG.md
rm CHANGELOG.md.bak

echo "✅ CHANGELOG.md updated"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Commit changelog update
# ─────────────────────────────────────────────────────────────────────────────

echo "💾 Committing CHANGELOG.md..."
git add CHANGELOG.md
git commit -m "chore: update CHANGELOG for $VERSION release

$DESCRIPTION"

echo "✅ Changes committed"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Create annotated tag
# ─────────────────────────────────────────────────────────────────────────────

echo "🏷️  Creating tag $VERSION..."

TAG_MESSAGE="Release $VERSION

$DESCRIPTION

Changes in this release:
$(git log "$LAST_TAG"..HEAD --oneline --no-merges | head -10)

Full changelog: https://github.com/your-org/repo/blob/main/CHANGELOG.md"

git tag -a "$VERSION" -m "$TAG_MESSAGE"

echo "✅ Tag created"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Push changes
# ─────────────────────────────────────────────────────────────────────────────

echo "📤 Pushing changes to remote..."
git push origin main
git push origin "$VERSION"

echo "✅ Changes pushed"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Create GitHub release (if gh CLI is available)
# ─────────────────────────────────────────────────────────────────────────────

if command -v gh &> /dev/null; then
  echo "📦 Creating GitHub release..."
  
  RELEASE_NOTES="## $DESCRIPTION

### Changes
$(git log "$LAST_TAG"..HEAD --oneline --no-merges | sed 's/^/- /')

### Installation

\`\`\`hcl
module \"webserver_cluster\" {
  source = \"git::https://github.com/your-org/repo.git//modules/webserver-cluster?ref=$VERSION\"
  
  # ... configuration
}
\`\`\`

### Documentation
- [CHANGELOG](https://github.com/your-org/repo/blob/$VERSION/CHANGELOG.md)
- [README](https://github.com/your-org/repo/blob/$VERSION/README.md)"

  gh release create "$VERSION" \
    --title "Release $VERSION" \
    --notes "$RELEASE_NOTES"
  
  echo "✅ GitHub release created"
else
  echo "⚠️  GitHub CLI not installed - skipping GitHub release creation"
  echo "   Create release manually at: https://github.com/your-org/repo/releases/new"
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Release $VERSION created successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Update consuming repositories to use $VERSION"
echo "  2. Announce release in team channels"
echo "  3. Update documentation if needed"
echo ""
echo "Module reference:"
echo "  source = \"git::https://github.com/your-org/repo.git//modules/webserver-cluster?ref=$VERSION\""
echo ""
echo "View release:"
echo "  https://github.com/your-org/repo/releases/tag/$VERSION"
echo ""

# Made with Bob
