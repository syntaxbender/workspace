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

echo "==> Installing virtualization tools"

brew install --cask \
  vagrant \
  orbstack

echo "==> Installing infrastructure tools"

brew tap hashicorp/tap
brew trust --formula hashicorp/tap/terraform
brew install hashicorp/tap/terraform
brew install terragrunt

echo "==> Installing helpers"
brew install \
  jq \
  yq \
  wget \
  curl \
  openssl

echo "==> Installing VPN clients"

brew install wireguard-tools

brew install --cask \
  tunnelblick \
  
echo "==> Installing database tools"

brew install \
  libpq \
  redis

brew install --cask dbeaver-community

echo "==> Installing file and storage tools"

brew install rclone
brew install --cask filezilla

echo
echo "DevOps stack installed."
