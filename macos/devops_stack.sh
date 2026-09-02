#!/usr/bin/env bash

set -euo pipefail

echo "==> Updating Homebrew"
brew update

echo "==> Installing Kubernetes tools"
brew install \
  kubectl \
  kubectx \
  helm

# kubectx also provides kubens.
# fzf is installed by workspace.sh and kubectx/kubens will use it automatically.

echo "==> Installing Freelens"
brew install --cask freelens

echo "==> Installing secrets tools"
brew install \
  sops \
  age \
  gnupg

echo "==> Installing helm-secrets"

if ! helm plugin list 2>/dev/null | grep -q '^secrets[[:space:]]'; then
  helm plugin install \
    oci://ghcr.io/jkroepke/helm-secrets/secrets:latest \
    --verify=false
fi

if ! helm plugin list 2>/dev/null | grep -q '^secrets-getter[[:space:]]'; then
  helm plugin install \
    oci://ghcr.io/jkroepke/helm-secrets/secrets-getter:latest \
    --verify=false
fi

if ! helm plugin list 2>/dev/null | grep -q '^secrets-post-renderer[[:space:]]'; then
  helm plugin install \
    oci://ghcr.io/jkroepke/helm-secrets/secrets-post-renderer:latest \
    --verify=false
fi

echo "==> Installing cloud CLIs"
brew install awscli
brew install --cask gcloud-cli

echo "==> Installing infrastructure tools"
brew install \
  terraform \
  terragrunt

echo "==> Installing helpers"
brew install \
  jq \
  yq \
  wget \
  curl \
  openssl

echo
echo "DevOps stack installed."
