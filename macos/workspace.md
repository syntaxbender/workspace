```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git curl wget fzf ripgrep fd bat eza zoxide jq tree htop ncdu tmux lazygit
brew install --cask ghostty font-meslo-for-powerlevel10k

brew install --cask rectangle
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"


git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"


cp ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d%H%M%S) 2>/dev/null

cat > ~/.zshrc <<'EOF'
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-completions zsh-syntax-highlighting)

source "$ZSH/oh-my-zsh.sh"

# ---- terminal productivity ----
# fzf: Ctrl+R history, Ctrl+T file picker, Alt+C directory jump
source <(fzf --zsh)

# zoxide: akıllı cd alternatifi
eval "$(zoxide init zsh)"

# better defaults
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {} 2>/dev/null || cat {}'"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -la --icons=auto --group-directories-first'
alias la='eza -a --icons=auto --group-directories-first'
alias cat='bat --paging=never --style=plain'
alias grep='rg'
alias du1='ncdu'
alias lg='lazygit'

# Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# ---- terminal productivity ----
EOF

source ~/.zshrc

mkdir -p ~/.config/ghostty

cat > ~/.config/ghostty/config <<'EOF'
font-family = "MesloLGS NF"
font-size = 14
window-padding-x = 8
window-padding-y = 8
EOF

brew install --cask google-chrome
brew install --cask kate

sudo xattr -rd com.apple.quarantine "/Applications/Visual Studio Code.app"
sudo xattr -rd com.apple.quarantine "/Applications/Kate.app"
```
