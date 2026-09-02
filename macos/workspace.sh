#!/bin/bash

set -e

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

brew install \
    git \
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
    lazygit


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

    RUNZSH=no CHSH=no sh -c \
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

cat > "$HOME/.zshrc" <<'EOF'
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


# ------------------------------------------------------------
# Ghostty
# ------------------------------------------------------------

echo "==> Ghostty yapılandırılıyor..."

mkdir -p "$HOME/.config/ghostty"

cat > "$HOME/.config/ghostty/config" <<'EOF'
font-family = "MesloLGS NF"
font-size = 14
window-padding-x = 8
window-padding-y = 8
EOF


# ------------------------------------------------------------
# GUI applications
# ------------------------------------------------------------

echo "==> GUI uygulamaları kuruluyor..."

brew install --cask google-chrome
brew install --cask kate


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
