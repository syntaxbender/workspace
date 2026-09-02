#!/usr/bin/env bash

set -euo pipefail

HELM_SECRETS_VERSION="4.7.7"

log() {
  printf '\n\033[1;34m==>\033[0m %s\n' "$1"
}

warn() {
  printf '\033[1;33mWARN:\033[0m %s\n' "$1"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

brew_install() {
  local package="$1"

  if brew list --formula "$package" >/dev/null 2>&1; then
    echo "$package already installed"
  else
    log "Installing $package"
    brew install "$package"
  fi
}

brew_install_cask() {
  local package="$1"

  if brew list --cask "$package" >/dev/null 2>&1; then
    echo "$package already installed"
  else
    log "Installing $package"
    brew install --cask "$package"
  fi
}

helm_plugin_exists() {
  local plugin="$1"

  helm plugin list 2>/dev/null \
    | awk 'NR > 1 { print $1 }' \
    | grep -qx "$plugin"
}

install_helm_secrets() {
  local helm_major

  helm_major="$(
    helm version --template '{{.Version}}' 2>/dev/null \
      | sed -E 's/^v([0-9]+).*/\1/'
  )"

  if [[ -z "$helm_major" ]]; then
    warn "Could not detect Helm major version"
    return 1
  fi

  log "Detected Helm major version: $helm_major"

  if [[ "$helm_major" -ge 4 ]]; then
    if ! helm_plugin_exists "secrets"; then
      log "Installing helm-secrets core plugin"
      helm plugin install \
        "oci://ghcr.io/jkroepke/helm-secrets/secrets:${HELM_SECRETS_VERSION}"
    else
      echo "helm-secrets core plugin already installed"
    fi

    if ! helm_plugin_exists "secrets-getter"; then
      log "Installing helm-secrets getter plugin"
      helm plugin install \
        "oci://ghcr.io/jkroepke/helm-secrets/secrets-getter:${HELM_SECRETS_VERSION}"
    else
      echo "helm-secrets getter plugin already installed"
    fi

    if ! helm_plugin_exists "secrets-post-renderer"; then
      log "Installing helm-secrets post-renderer plugin"
      helm plugin install \
        "oci://ghcr.io/jkroepke/helm-secrets/secrets-post-renderer:${HELM_SECRETS_VERSION}"
    else
      echo "helm-secrets post-renderer plugin already installed"
    fi
  else
    if helm_plugin_exists "secrets"; then
      echo "helm-secrets already installed"
    else
      log "Installing helm-secrets"
      helm plugin install \
        https://github.com/jkroepke/helm-secrets \
        --version "v${HELM_SECRETS_VERSION}"
    fi
  fi
}

# --------------------------------------------------
# Preflight
# --------------------------------------------------

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This script currently supports macOS only."
  exit 1
fi

if ! command_exists brew; then
  echo "Homebrew is required."
  echo "Run workspace.sh first or install Homebrew."
  exit 1
fi

log "Updating Homebrew"
brew update

# --------------------------------------------------
# Kubernetes
# --------------------------------------------------

log "Installing Kubernetes tools"

brew_install kubectl
brew_install kubectx
brew_install helm

# kubectx package provides:
# - kubectx
# - kubens

# --------------------------------------------------
# Secrets management
# --------------------------------------------------

log "Installing secrets management tools"

brew_install sops
brew_install age

install_helm_secrets

# --------------------------------------------------
# Cloud CLIs
# --------------------------------------------------

log "Installing cloud CLIs"

brew_install awscli
brew_install_cask gcloud-cli

# --------------------------------------------------
# Infrastructure as Code
# --------------------------------------------------

log "Installing infrastructure tools"

brew_install terraform
brew_install terragrunt

# --------------------------------------------------
# Helpers
# --------------------------------------------------

log "Installing DevOps helpers"

brew_install jq
brew_install yq
brew_install wget
brew_install curl
brew_install openssl

# --------------------------------------------------
# Verification
# --------------------------------------------------

log "Installed versions"

printf '%-20s %s\n' \
  "kubectl" \
  "$(kubectl version --client 2>/dev/null | head -n1 || true)"

printf '%-20s %s\n' \
  "kubectx" \
  "$(kubectx --version 2>/dev/null || true)"

printf '%-20s %s\n' \
  "kubens" \
  "$(command -v kubens || true)"

printf '%-20s %s\n' \
  "helm" \
  "$(helm version --short 2>/dev/null || true)"

printf '%-20s %s\n' \
  "helm-secrets" \
  "$(helm secrets --version 2>/dev/null || true)"

printf '%-20s %s\n' \
  "sops" \
  "$(sops --version 2>/dev/null | head -n1 || true)"

printf '%-20s %s\n' \
  "age" \
  "$(age --version 2>/dev/null || true)"

printf '%-20s %s\n' \
  "age-keygen" \
  "$(age-keygen --version 2>/dev/null || true)"

printf '%-20s %s\n' \
  "aws" \
  "$(aws --version 2>&1 || true)"

printf '%-20s %s\n' \
  "gcloud" \
  "$(gcloud version 2>/dev/null | head -n1 || true)"

printf '%-20s %s\n' \
  "terraform" \
  "$(terraform version 2>/dev/null | head -n1 || true)"

printf '%-20s %s\n' \
  "terragrunt" \
  "$(terragrunt --version 2>/dev/null || true)"

printf '%-20s %s\n' \
  "jq" \
  "$(jq --version 2>/dev/null || true)"

printf '%-20s %s\n' \
  "yq" \
  "$(yq --version 2>/dev/null || true)"

# --------------------------------------------------
# Finish
# --------------------------------------------------

log "DevOps stack installation complete"

echo
echo "Authentication/configuration is intentionally not automated:"
echo
echo "  AWS:"
echo "    aws configure"
echo
echo "  GCP:"
echo "    gcloud auth login"
echo "    gcloud auth application-default login"
echo
echo "  Kubernetes:"
echo "    configure ~/.kube/config"
echo
echo "  SOPS/age:"
echo "    age-keygen -o ~/.config/sops/age/keys.txt"
