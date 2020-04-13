#!/bin/sh

sudo pacman -S git go gvim curl zsh reflector rofi otf-fira-code otf-fira-sans otf-fire-mono ttf-dejavu chromium feh vlc flameshot kitty rxvt-unicode
[ $? -ne 0 ] && exit 1
cd /tmp
git clone https://aur.archlinux.org/yay.git
[ $? -ne 0 ] && exit 2
cd yay
makepkg -si
[ $? -ne 0 ] && exit 3

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
[ $? -ne 0 ] && exit 4

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
[ $? -ne 0 ] && exit 5

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
[ $? -ne 0 ] && exit 6

cp xinitrc ~/.xinitrc
cp -r i3 ~/.config
cp bashrc .bashrc
cp zshrc .zshrc
cp -r dracula/* ~/.oh-my-zsh/themes
cp Xresources ~/.Xresources
sudo reflector --verbose --country 'France' -l 10 -p https --sort rate --save /etc/pacman.d/mirrorlist
cp vimrc ~/.vimrc
