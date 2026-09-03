#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_vscode_extension() {
  local extension="$1"

  if code --list-extensions | grep -qxF "$extension"; then
    echo "==> VS Code extension already installed: $extension"
    return
  fi

  echo "==> Installing VS Code extension: $extension"
  code --install-extension "$extension"
}

install_firefox_extension() {
  local extension_id="$1"
  local extension_slug="$2"
  local policy="ExtensionSettings__${extension_id}"

  sudo defaults write /Library/Preferences/org.mozilla.firefox \
      "${policy}__installation_mode" -string normal_installed
  sudo defaults write /Library/Preferences/org.mozilla.firefox \
      "${policy}__install_url" -string \
      "https://addons.mozilla.org/firefox/downloads/latest/${extension_slug}/latest.xpi"
}

add_ghostty_default() {
    local key="$1"
    local setting="$2"

    if /usr/bin/grep -Eq "^[[:space:]]*${key}[[:space:]]*=" "$GHOSTTY_CONFIG"; then
        return
    fi

    if [[ "$GHOSTTY_SETTING_ADDED" == false && -s "$GHOSTTY_CONFIG" ]]; then
        printf '\n' >> "$GHOSTTY_CONFIG"
    fi

    printf '%s\n' "$setting" >> "$GHOSTTY_CONFIG"
    GHOSTTY_SETTING_ADDED=true
}

echo "==> macOS workspace kurulumu başlıyor..."

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------

if ! command -v brew >/dev/null 2>&1; then
    echo "==> Homebrew kuruluyor..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "==> Homebrew zaten kurulu."
fi

# Homebrew'u mevcut script'in PATH'ine ekle.
# Apple Silicon: /opt/homebrew
# Intel:         /usr/local
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"

    if ! grep -q '/opt/homebrew/bin/brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi

elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"

    if ! grep -q '/usr/local/bin/brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi
else
    echo "ERROR: Homebrew kuruldu ancak brew executable bulunamadı."
    exit 1
fi


# ------------------------------------------------------------
# CLI tools
# ------------------------------------------------------------

echo "==> CLI araçları kuruluyor..."

if ! command -v git >/dev/null 2>&1 || ! git --version >/dev/null 2>&1; then
    echo "==> Git kuruluyor..."
    brew install git
else
    echo "==> Git zaten kurulu."
fi

git config --global user.name "Hasan Ozer"
git config --global user.email "hasan.ozer@local"

brew install \
    curl \
    wget \
    fzf \
    ripgrep \
    fd \
    bat \
    eza \
    zoxide \
    jq \
    tree \
    htop \
    ncdu \
    tmux \
    lazygit \
    nano

# ------------------------------------------------------------
# Ghostty + Powerlevel10k font
# ------------------------------------------------------------

echo "==> Terminal araçları kuruluyor..."

brew install --cask ghostty
brew install --cask font-meslo-for-powerlevel10k

# ------------------------------------------------------------
# Rectangle
# ------------------------------------------------------------

brew install --cask rectangle


# ------------------------------------------------------------
# Oh My Zsh
# ------------------------------------------------------------

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "==> Oh My Zsh kuruluyor..."

    # Installer'ın mevcut .zshrc dosyasını kendi şablonuyla değiştirmesini önle.
    if [[ ! -e "$HOME/.zshrc" ]]; then
        touch "$HOME/.zshrc"
    fi

    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "==> Oh My Zsh zaten kurulu."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"


# ------------------------------------------------------------
# Zsh plugin helper
# ------------------------------------------------------------

clone_or_update() {
    local repo="$1"
    local dest="$2"

    if [[ -d "$dest/.git" ]]; then
        echo "==> Güncelleniyor: $dest"
        git -C "$dest" pull --ff-only
    elif [[ -e "$dest" ]]; then
        echo "WARNING: $dest mevcut ama git repository değil. Dokunulmadı."
    else
        echo "==> Clone ediliyor: $repo"
        git clone --depth=1 "$repo" "$dest"
    fi
}


# ------------------------------------------------------------
# Powerlevel10k + plugins
# ------------------------------------------------------------

clone_or_update \
    "https://github.com/romkatv/powerlevel10k.git" \
    "$ZSH_CUSTOM/themes/powerlevel10k"

clone_or_update \
    "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

clone_or_update \
    "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

clone_or_update \
    "https://github.com/zsh-users/zsh-completions.git" \
    "$ZSH_CUSTOM/plugins/zsh-completions"


# ------------------------------------------------------------
# .zshrc
# ------------------------------------------------------------

if [[ -f "$HOME/.zshrc" ]]; then
    BACKUP="$HOME/.zshrc.bak.$(date +%Y%m%d%H%M%S)"
    echo "==> Mevcut .zshrc yedekleniyor: $BACKUP"
    cp "$HOME/.zshrc" "$BACKUP"
fi

ZSH_CONFIG_DIR="$HOME/.config/workspace/zshrc.d"
WORKSPACE_ZSH_CONFIG="$ZSH_CONFIG_DIR/10-workspace.zsh"
ZSH_CONFIG_LOADER='for config_file in "$HOME"/.config/workspace/zshrc.d/*.zsh(N); do source "$config_file"; done; unset config_file'

mkdir -p "$ZSH_CONFIG_DIR"

cat > "$WORKSPACE_ZSH_CONFIG" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    zsh-autosuggestions
    zsh-completions
    zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"


# ------------------------------------------------------------
# Terminal productivity
# ------------------------------------------------------------

# fzf
# Ctrl+R -> history
# Ctrl+T -> file picker
# Alt+C  -> directory jump
source <(fzf --zsh)


# zoxide
# Akıllı cd alternatifi
eval "$(zoxide init zsh)"


# ------------------------------------------------------------
# fzf defaults
# ------------------------------------------------------------

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {} 2>/dev/null || cat {}'"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"


# ------------------------------------------------------------
# Aliases
# ------------------------------------------------------------

alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -la --icons=auto --group-directories-first'
alias la='eza -a --icons=auto --group-directories-first'

alias cat='bat --paging=never --style=plain'
alias grep='rg'

alias du1='ncdu'
alias lg='lazygit'


# ------------------------------------------------------------
# Powerlevel10k
# ------------------------------------------------------------

[[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"
EOF

if [[ ! -e "$HOME/.zshrc" ]]; then
    touch "$HOME/.zshrc"
fi

WORKSPACE_ZSH_CONFIG_LINES="$(wc -l < "$WORKSPACE_ZSH_CONFIG" | tr -d '[:space:]')"
LEGACY_ZSH_CONFIG_START="$(
    /usr/bin/grep -n -m 1 -xF 'export ZSH="$HOME/.oh-my-zsh"' "$HOME/.zshrc" \
        | cut -d: -f1
)"

if [[ -n "$LEGACY_ZSH_CONFIG_START" ]]; then
    LEGACY_ZSH_CONFIG_END="$((
        LEGACY_ZSH_CONFIG_START + WORKSPACE_ZSH_CONFIG_LINES - 1
    ))"

    if sed -n "${LEGACY_ZSH_CONFIG_START},${LEGACY_ZSH_CONFIG_END}p" "$HOME/.zshrc" \
        | cmp -s - "$WORKSPACE_ZSH_CONFIG"; then
        echo "==> Eski workspace .zshrc içeriği yönetilen config'e taşınıyor..."
        sed -i '' "${LEGACY_ZSH_CONFIG_START},${LEGACY_ZSH_CONFIG_END}d" "$HOME/.zshrc"
    fi
fi

if ! /usr/bin/grep -qxF "$ZSH_CONFIG_LOADER" "$HOME/.zshrc"; then
    printf '\n%s\n' "$ZSH_CONFIG_LOADER" >> "$HOME/.zshrc"
fi


# ------------------------------------------------------------
# Ghostty
# ------------------------------------------------------------

echo "==> Ghostty yapılandırılıyor..."

mkdir -p "$HOME/.config/ghostty"

GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
GHOSTTY_SETTING_ADDED=false

if [[ ! -e "$GHOSTTY_CONFIG" ]]; then
    touch "$GHOSTTY_CONFIG"
fi

add_ghostty_default "font-family" 'font-family = "MesloLGS NF"'
add_ghostty_default "font-size" "font-size = 15"
add_ghostty_default "window-padding-x" "window-padding-x = 8"
add_ghostty_default "window-padding-y" "window-padding-y = 8"

# ------------------------------------------------------------
# macOS Terminal
# ------------------------------------------------------------

echo "==> macOS Terminal yapılandırılıyor..."

TERMINAL_PROFILE_NAME="Clear Dark Customized"
TERMINAL_PROFILE_FILE="$SCRIPT_DIR/terminal/clear_dark_customized.terminal"

if [[ ! -f "$TERMINAL_PROFILE_FILE" ]]; then
    echo "ERROR: Terminal profil dosyası bulunamadı:"
    echo "  $TERMINAL_PROFILE_FILE"
    exit 1
fi

TERMINAL_PROFILE_READY=false

if defaults read com.apple.Terminal "Window Settings" 2>/dev/null \
    | grep -Fq "$TERMINAL_PROFILE_NAME"; then
    echo "==> Terminal profili zaten kurulu."
    TERMINAL_PROFILE_READY=true
else
    echo "==> Terminal profili import ediliyor..."
    open -a Terminal "$TERMINAL_PROFILE_FILE"

    for _ in {1..10}; do
        if defaults read com.apple.Terminal "Window Settings" 2>/dev/null \
            | grep -Fq "$TERMINAL_PROFILE_NAME"; then
            TERMINAL_PROFILE_READY=true
            break
        fi

        sleep 0.5
    done
fi

if [[ "$TERMINAL_PROFILE_READY" == true ]]; then
    defaults write com.apple.Terminal \
        "Default Window Settings" \
        -string "$TERMINAL_PROFILE_NAME"

    defaults write com.apple.Terminal \
        "Startup Window Settings" \
        -string "$TERMINAL_PROFILE_NAME"
else
    echo "WARNING: Terminal profil import'u başarısız; profil ayarları atlandı."
fi

# ------------------------------------------------------------
# macOS preferences
# ------------------------------------------------------------

echo "==> macOS ayarları uygulanıyor..."

# Dock icon boyutu
defaults write com.apple.dock tilesize -int 42

# Dock'u yeniden başlat
killall Dock 2>/dev/null || true


# ------------------------------------------------------------
# Keyboard shortcuts
# ------------------------------------------------------------

echo '==> Keyboard shortcuts ayarlanıyor...'

# Aynı uygulamanın pencereleri arasında geçiş: Command + "
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 27 \
'{
    enabled = 1;
    value = {
        parameters = (
            34,
            10,
            1048576
        );
        type = standard;
    };
}'

ACTIVATE_SETTINGS="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"

if [[ -x "$ACTIVATE_SETTINGS" ]]; then
    "$ACTIVATE_SETTINGS" -u
fi

# ------------------------------------------------------------
# GUI applications
# ------------------------------------------------------------

echo "==> GUI uygulamaları kuruluyor..."

brew install --cask google-chrome
brew install --cask firefox

# Firefox extensions
sudo defaults write /Library/Preferences/org.mozilla.firefox \
    EnterprisePoliciesEnabled -bool true

install_firefox_extension 'foxyproxy@eric.h.jung' foxyproxy-standard
install_firefox_extension 'uBlock0@raymondhill.net' ublock-origin
install_firefox_extension 'addon@darkreader.org' darkreader
install_firefox_extension 'firefox-extension@deepl.com' deepl-translate

# Chrome extensions
CHROME_EXT_DIR="$HOME/Library/Application Support/Google/Chrome/External Extensions"
mkdir -p "$CHROME_EXT_DIR"

for EXT_ID in \
    eimadpbcbfnmbkopoojfekhnkhdbieeh \
    ddkjiahejlhfcafbddmgiahcphecmpfh \
    cofdbpoegempjloogbagkncekinflcnj
do
    cat > "$CHROME_EXT_DIR/$EXT_ID.json" <<'EOF'
{
    "external_update_url": "https://clients2.google.com/service/update2/crx"
}
EOF
done

brew install --cask kate
brew install --cask visual-studio-code

install_vscode_extension anthropic.claude-code
install_vscode_extension openai.chatgpt
install_vscode_extension ms-vscode-remote.remote-ssh
install_vscode_extension hashicorp.hcl

brew tap lzhgus/tap
brew trust --cask lzhgus/tap/capso
brew install --cask capso
brew install --cask spotify

# Kate editor font
mkdir -p "$HOME/Library/Preferences"
KATE_CONFIG="$HOME/Library/Preferences/katerc"
KATE_SECTION="[KTextEditor Renderer]"
KATE_FONT_SETTING="Text Font=Menlo,15,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"

if [[ ! -e "$KATE_CONFIG" ]]; then
    touch "$KATE_CONFIG"
fi

if /usr/bin/grep -q '^Text Font=' "$KATE_CONFIG"; then
    sed -i '' "s/^Text Font=.*/$KATE_FONT_SETTING/" "$KATE_CONFIG"
elif /usr/bin/grep -qxF "$KATE_SECTION" "$KATE_CONFIG"; then
    KATE_SECTION_LINE="$(
        /usr/bin/grep -n -m 1 -xF "$KATE_SECTION" "$KATE_CONFIG" \
            | cut -d: -f1
    )"

    sed -i '' "${KATE_SECTION_LINE}a\\
$KATE_FONT_SETTING
" "$KATE_CONFIG"
else
    printf '\n%s\n%s\n' "$KATE_SECTION" "$KATE_FONT_SETTING" >> "$KATE_CONFIG"
fi

# ------------------------------------------------------------
# Quarantine temizliği
# ------------------------------------------------------------

# Kate Homebrew tarafından küçük harfle kate.app olarak kuruluyor.
if [[ -d "/Applications/kate.app" ]]; then
    sudo xattr -rd com.apple.quarantine "/Applications/kate.app" 2>/dev/null || true
fi

# VS Code sistemde zaten varsa temizle.
# Yoksa hata verme.
if [[ -d "/Applications/Visual Studio Code.app" ]]; then
    sudo xattr -rd com.apple.quarantine "/Applications/Visual Studio Code.app" 2>/dev/null || true
fi


# ------------------------------------------------------------
# Final validation
# ------------------------------------------------------------

echo
echo "=========================================="
echo " Kurulum tamamlandı."
echo "=========================================="
echo
echo "Zsh config kontrol ediliyor..."

if /bin/zsh -ic 'echo "Zsh OK"' >/dev/null 2>&1; then
    echo "✓ .zshrc başarıyla yükleniyor."
else
    echo "WARNING: .zshrc yüklenirken hata oluştu."
    echo "Kontrol etmek için:"
    echo
    echo "  zsh -ic 'source ~/.zshrc'"
fi

echo
echo "Terminali kapatıp yeniden aç."
echo
echo "Powerlevel10k ilk açılışta konfigürasyon sorarsa"
echo "wizard'ı tamamlayabilirsin."
echo
