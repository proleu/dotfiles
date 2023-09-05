# History
setopt histignorealldups sharehistory
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=$HOME/.zsh_history

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Paths
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

export ZSH="$HOME/.oh-my-zsh"
export FZF_BASE="$HOME/.fzf"

# Plugins
# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    fzf 
    git 
    history-substring-search 
    ohmyzsh-full-autoupdate
    # thefuck 
    zsh-autosuggestions 
    zsh-completions 
    zsh-vi-mode
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nvim'
fi

# Use vi keybindings
bindkey -v

# Aliases
alias b="cd .."
alias bb="cd ../.."
alias bbb="cd ../../.."
alias bbbb="cd ../../../.."
alias bbbbb="cd ../../../../.."
alias bbbbbb="cd ../../../../../.."
alias myq="squeue -u $USER"
alias pnuke="perl -e 'for(<*>){unlink}'"
alias so="source $HOME/.zshrc"
alias vi="nvim"
alias watch="watch "
# Functions
function count_pdbs()
{
	find -type f -name "*.pdb*" | wc -l
}
function fetch() {
        wget http://www.rcsb.org/pdb/files/$1.pdb.gz || wget ftp://ftp.wwpdb.org/pub/pdb/data/structures/all/pdb/pdb$1.ent.gz
}
function mcd()
{
    mkdir -p $1; cd $1
}
function swap()
{
    local TMPFILE=tmp.$$
    mv "$1" $TMPFILE
    mv "$2" "$1"
    mv $TMPFILE "$2"
}

# Unused
# Use modern completion system
# autoload -Uz compinit
# compinit
# 
# zstyle ':completion:*' auto-description 'specify: %d'
# zstyle ':completion:*' completer _expand _complete _correct _approximate
# zstyle ':completion:*' format 'Completing %d'
# zstyle ':completion:*' group-name ''
# zstyle ':completion:*' menu select=2
# eval "$(dircolors -b)"
# zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# zstyle ':completion:*' list-colors ''
# zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
# zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
# zstyle ':completion:*' menu select=long
# zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
# zstyle ':completion:*' use-compctl false
# zstyle ':completion:*' verbose true
# 
# zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
# zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/software/conda/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/software/conda/etc/profile.d/conda.sh" ]; then
        . "/software/conda/etc/profile.d/conda.sh"
    else
        export PATH="/software/conda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
export PATH="$PATH":/home/pleung/software/silent_tools/
