#!/usr/bin/env bash
# ==============================================================================
# scripts/setup-dev-environment.sh
#
# PURPOSE: One-command setup for new developers joining the infrastructure team.
# Installs all required tools and configures the development environment.
#
# USAGE:
#   ./scripts/setup-dev-environment.sh
# ==============================================================================

set -euo pipefail

echo "🚀 Setting up infrastructure development environment..."
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Detect OS
# ─────────────────────────────────────────────────────────────────────────────

OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    MINGW*)     MACHINE=Windows;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "📋 Detected OS: $MACHINE"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Install pre-commit
# ─────────────────────────────────────────────────────────────────────────────

echo "📦 Installing pre-commit..."
if command -v pre-commit &> /dev/null; then
    echo "  ✅ pre-commit already installed ($(pre-commit --version))"
else
    if command -v pip3 &> /dev/null; then
        pip3 install pre-commit
        echo "  ✅ pre-commit installed"
    elif command -v pip &> /dev/null; then
        pip install pre-commit
        echo "  ✅ pre-commit installed"
    else
        echo "  ❌ pip not found. Please install Python and pip first."
        exit 1
    fi
fi

# Install pre-commit hooks
echo "  Installing pre-commit hooks..."
pre-commit install
pre-commit install --hook-type commit-msg
echo "  ✅ Pre-commit hooks installed"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Configure git commit template
# ─────────────────────────────────────────────────────────────────────────────

echo "📝 Configuring git commit template..."
git config commit.template .gitmessage
echo "  ✅ Commit template configured"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Install tflint
# ─────────────────────────────────────────────────────────────────────────────

echo "🔍 Installing tflint..."
if command -v tflint &> /dev/null; then
    echo "  ✅ tflint already installed ($(tflint --version))"
else
    case "${MACHINE}" in
        Linux)
            curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
            ;;
        Mac)
            if command -v brew &> /dev/null; then
                brew install tflint
            else
                curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
            fi
            ;;
        Windows)
            echo "  ⚠️  Please install tflint manually from: https://github.com/terraform-linters/tflint/releases"
            ;;
    esac
    echo "  ✅ tflint installed"
fi

# Initialize tflint plugins
echo "  Initializing tflint plugins..."
tflint --init
echo "  ✅ tflint plugins initialized"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Install tfsec
# ─────────────────────────────────────────────────────────────────────────────

echo "🔒 Installing tfsec..."
if command -v tfsec &> /dev/null; then
    echo "  ✅ tfsec already installed ($(tfsec --version))"
else
    case "${MACHINE}" in
        Linux)
            curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
            ;;
        Mac)
            if command -v brew &> /dev/null; then
                brew install tfsec
            else
                curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
            fi
            ;;
        Windows)
            echo "  ⚠️  Please install tfsec manually from: https://github.com/aquasecurity/tfsec/releases"
            ;;
    esac
    echo "  ✅ tfsec installed"
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Install terraform-docs (optional but recommended)
# ─────────────────────────────────────────────────────────────────────────────

echo "📚 Installing terraform-docs..."
if command -v terraform-docs &> /dev/null; then
    echo "  ✅ terraform-docs already installed ($(terraform-docs --version))"
else
    case "${MACHINE}" in
        Mac)
            if command -v brew &> /dev/null; then
                brew install terraform-docs
                echo "  ✅ terraform-docs installed"
            else
                echo "  ⚠️  Homebrew not found. Skipping terraform-docs."
            fi
            ;;
        Linux)
            echo "  ⚠️  Please install terraform-docs manually from: https://github.com/terraform-docs/terraform-docs/releases"
            ;;
        Windows)
            echo "  ⚠️  Please install terraform-docs manually from: https://github.com/terraform-docs/terraform-docs/releases"
            ;;
    esac
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Verify Terraform installation
# ─────────────────────────────────────────────────────────────────────────────

echo "🏗️  Verifying Terraform installation..."
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    echo "  ✅ Terraform installed: v$TERRAFORM_VERSION"
    
    # Check if version is 1.6+ (required for terraform test)
    MAJOR=$(echo "$TERRAFORM_VERSION" | cut -d. -f1)
    MINOR=$(echo "$TERRAFORM_VERSION" | cut -d. -f2)
    
    if [ "$MAJOR" -ge 1 ] && [ "$MINOR" -ge 6 ]; then
        echo "  ✅ Terraform version supports native testing"
    else
        echo "  ⚠️  Terraform 1.6+ recommended for native testing (current: $TERRAFORM_VERSION)"
    fi
else
    echo "  ❌ Terraform not found. Please install from: https://www.terraform.io/downloads"
    exit 1
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Verify AWS CLI installation
# ─────────────────────────────────────────────────────────────────────────────

echo "☁️  Verifying AWS CLI installation..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1 | cut -d'/' -f2)
    echo "  ✅ AWS CLI installed: v$AWS_VERSION"
else
    echo "  ⚠️  AWS CLI not found. Install from: https://aws.amazon.com/cli/"
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Run initial pre-commit check
# ─────────────────────────────────────────────────────────────────────────────

echo "🧪 Running initial pre-commit checks..."
if pre-commit run --all-files; then
    echo "  ✅ All pre-commit checks passed"
else
    echo "  ⚠️  Some pre-commit checks failed. This is normal for first run."
    echo "     Run 'pre-commit run --all-files' again after fixing issues."
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Development environment setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Configure AWS credentials: aws configure"
echo "  2. Review commit message template: cat .gitmessage"
echo "  3. Read workflow guide: cat IMPLEMENTATION_GUIDE.md"
echo "  4. Create your first feature branch: git checkout -b feat-your-change"
echo ""
echo "Useful commands:"
echo "  • Run pre-commit manually: pre-commit run --all-files"
echo "  • Format Terraform: terraform fmt -recursive"
echo "  • Validate Terraform: terraform validate"
echo "  • Run tests: terraform test"
echo "  • Lint: tflint"
echo "  • Security scan: tfsec ."
echo ""
echo "Need help? Check IMPLEMENTATION_GUIDE.md or ask in #infrastructure-team"
echo ""

# Made with Bob
