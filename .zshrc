# History
setopt histignorealldups sharehistory
HISTSIZE=SAVEHIST=10000
HISTFILE=$HOME/.zsh_history

# Theme
ZSH_THEME="robbyrussell"

# Paths
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
export ZSH="$HOME/.oh-my-zsh"

# Plugins
plugins=(
    fzf 
    git 
    history-substring-search 
    ohmyzsh-full-autoupdate 
    zsh-autosuggestions 
    zsh-completions 
    zsh-vi-mode
)

# Source Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# User Configuration
export EDITOR='nvim'
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
function count_pdbs() { find -type f -name "*.pdb*" | wc -l; }
function fetch() { wget http://www.rcsb.org/pdb/files/$1.pdb.gz || wget ftp://ftp.wwpdb.org/pub/pdb/data/structures/all/pdb/pdb$1.ent.gz; }
function mcd() { mkdir -p $1; cd $1; }
function swap() {
    local TMPFILE=tmp.$$
    mv "$1" $TMPFILE
    mv "$2" "$1"
    mv $TMPFILE "$2"
}
function dockerSummary() {
  for section in \
    "Containers:docker ps -a --format 'table {{.ID}}\t{{.Status}}\t{{.Names}}'" \
    "Images:docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'" \
    "Volumes:docker volume ls --format 'table {{.Driver}}\t{{.Name}}'" \
    "Networks:docker network ls --format 'table {{.Driver}}\t{{.Name}}'" \
    "Disk Usage:docker system df"
  do
    title="${section%%:*}"
    cmd="${section#*:}"
    echo -e "$title\n$($cmd | cut -c1-80)"
  done
}
