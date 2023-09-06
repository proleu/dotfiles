#!/usr/bin/sh
SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd $HOME
# check to see if zsh exists; install if not
# TODO test with 2nd bracket
if ! [ -x "$(command -v zsh)" ]; then
  sudo apt install zsh
  zsh --version
fi
# switch to zsh if not being used
if ! [[ $SHELL == "/bin/zsh" ]]; then
  chsh -s /bin/zsh
fi
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# build symlink to zshrc stored here
ln -s $HOME/.zshrc $SCRIPTPATH/.zshrc
# install zsh plugins automatically
git clone --depth 1 https://github.com/junegunn/fzf.git \
$HOME/.fzf
$HOME/.fzf/install
# TODO add checks for -d
git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git \ 
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate
git clone https://github.com/zsh-users/zsh-autosuggestions.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-completions.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/jeffreytse/zsh-vi-mode.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode

# build symlinks to this repo's dotfiles

ln -s ./.zshrc ~/.zshrc
# TODO ...

# install miniconda3 after downloading and verifying it
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
sha256sum Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# source zshrc
/usr/bin/zsh $HOME/.zshrc
# check to see if nvim exists; install if not
