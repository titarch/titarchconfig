#!/bin/sh
# qomz (Quick Oh My Zsh)
set -e

if ! [ -x "$(command -v curl)" ]; then
  echo 'Error: curl is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v git)" ]; then
  echo 'Error: git is not installed.' >&2
  exit 2
fi

if ! [ -x "$(command -v zsh)" ]; then
  echo 'Error: zsh is not installed.' >&2
  exit 3
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

if ! [ -x "$(command -v sudo)" ]; then
  echo 'Error: sudo is not installed, chsh skipped.' >&2
else
  sudo chsh -s $(which zsh) $(id -un)
fi

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/MichaelAquilina/zsh-autoswitch-virtualenv.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/autoswitch_virtualenv
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/superbrothers/zsh-kubectl-prompt.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-kubectl-prompt
git clone https://github.com/hanjunlee/terragrunt-oh-my-zsh-plugin ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/terragrunt

curl -o "$HOME"/.zshrc -L https://raw.githubusercontent.com/titarch/titarchconfig/master/zshrc
mkdir -p "$HOME"/.oh-my-zsh/themes/lib/
curl -o "$HOME"/.oh-my-zsh/themes/dracula.zsh-theme https://raw.githubusercontent.com/titarch/titarchconfig/master/dracula/dracula.zsh-theme
curl -o "$HOME"/.oh-my-zsh/themes/lib/async.zsh https://raw.githubusercontent.com/titarch/titarchconfig/master/dracula/lib/async.zsh
