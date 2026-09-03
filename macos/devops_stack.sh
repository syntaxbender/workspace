#!/usr/bin/env bash

set -euo pipefail

install_filezilla() {
  echo "==> Installing FileZilla"

  if [[ -d "/Applications/FileZilla.app" ]]; then
    echo "FileZilla already installed, skipping"
    return 0
  fi

  local page wrapper iv key data download_html filezilla_url tmp

  if ! page="$(
    curl -fsSL \
      -A 'Mozilla/5.0 (Macintosh; Apple Silicon Mac OS X)' \
      'https://filezilla-project.org/download.php?show_all=1' \
      | tr -d '\n'
  )"; then
    echo "Warning: Failed to fetch FileZilla download page, skipping"
    return 0
  fi

  wrapper="$(
    printf '%s' "$page" \
      | grep -o '<div hidden id="contentwrapper"[^>]*>[^<]*</div>' \
      | head -n1 \
      || true
  )"

  if [[ -z "$wrapper" ]]; then
    echo "Warning: FileZilla download metadata not found, skipping"
    return 0
  fi

  iv="$(
    printf '%s' "$wrapper" \
      | sed -E 's/.* v1="([^"]+)".*/\1/' \
      | /usr/bin/base64 -D \
      | od -An -tx1 \
      | tr -d ' \n'
  )"

  key="$(
    printf '%s' "$wrapper" \
      | sed -E 's/.* v2="([^"]+)".*/\1/' \
      | /usr/bin/base64 -D \
      | od -An -tx1 \
      | tr -d ' \n'
  )"

  data="$(
    printf '%s' "$wrapper" \
      | sed -E 's/^[^>]*>//; s#</div>$##'
  )"

  if ! download_html="$(
    printf '%s' "$data" \
      | /usr/bin/base64 -D \
      | openssl enc -d -aes-256-cbc -K "$key" -iv "$iv"
  )"; then
    echo "Warning: Failed to decode FileZilla download metadata, skipping"
    return 0
  fi

  filezilla_url="$(
    printf '%s' "$download_html" \
      | grep -o 'https://[^"]*FileZilla_[^"]*_macos-arm64\.app\.tar\.bz2[^"]*' \
      | head -n1 \
      | sed 's/&amp;/\&/g' \
      || true
  )"

  if [[ -z "$filezilla_url" ]]; then
    echo "Warning: FileZilla download URL not found, skipping"
    return 0
  fi

  tmp="$(mktemp -d)"

  if ! curl -fL "$filezilla_url" -o "$tmp/filezilla.tar.bz2"; then
    echo "Warning: Failed to download FileZilla, skipping"
    rm -rf "$tmp"
    return 0
  fi

  if ! tar -xjf "$tmp/filezilla.tar.bz2" -C "$tmp"; then
    echo "Warning: Failed to extract FileZilla, skipping"
    rm -rf "$tmp"
    return 0
  fi

  if [[ ! -d "$tmp/FileZilla.app" ]]; then
    echo "Warning: FileZilla.app not found in archive, skipping"
    rm -rf "$tmp"
    return 0
  fi

  mv "$tmp/FileZilla.app" /Applications/
  rm -rf "$tmp"

  echo "FileZilla installed successfully"
}

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
  warp
echo "==> Installing database tools"

brew install \
  libpq \
  redis

brew install --cask dbeaver-community

# libpq is keg-only
ZSH_CONFIG_DIR="$HOME/.config/workspace/zshrc.d"
DEVOPS_ZSH_CONFIG="$ZSH_CONFIG_DIR/20-devops.zsh"
ZSH_CONFIG_LOADER='for config_file in "$HOME"/.config/workspace/zshrc.d/*.zsh(N); do source "$config_file"; done; unset config_file'

mkdir -p "$ZSH_CONFIG_DIR"

cat > "$DEVOPS_ZSH_CONFIG" <<'EOF'
# This file is managed by devops_stack.sh.
if [[ ":$PATH:" != *":/opt/homebrew/opt/libpq/bin:"* ]]; then
  export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
fi
EOF

if [[ ! -e "$HOME/.zshrc" ]]; then
  touch "$HOME/.zshrc"
fi

if ! /usr/bin/grep -qxF "$ZSH_CONFIG_LOADER" "$HOME/.zshrc"; then
  printf '\n%s\n' "$ZSH_CONFIG_LOADER" >> "$HOME/.zshrc"
fi

echo "==> Installing file and storage tools"

brew install rclone
install_filezilla

echo
echo "DevOps stack installed."
