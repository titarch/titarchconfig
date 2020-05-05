#!/bin/sh

read -p "Refresh mirrors? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -S reflector
    [ $? -ne 0 ] && exit 1
    sudo reflector --verbose --country 'France' -l 10 -p https --sort rate --save /etc/pacman.d/mirrorlist
    [ $? -ne 0 ] && exit 1
fi

read -p "Install base packages? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -S git go gvim curl zsh rofi otf-fira-code otf-fira-sans otf-fira-mono ttf-dejavu chromium feh vlc flameshot kitty rxvt-unicode openssh playerctl pavucontrol thunar arandr
    [ $? -ne 0 ] && exit 1
fi

read -p "Install yay? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    [ $? -ne 0 ] && exit 2
    cd yay
    makepkg -si
    [ $? -ne 0 ] && exit 3
fi

read -p "Install oh-my-zsh? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    [ $? -ne 0 ] && exit 4
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    [ $? -ne 0 ] && exit 5
    cp -r dracula/* ~/.oh-my-zsh/themes
    [ $? -ne 0 ] && exit 6
    ln -s zshrc ~/.zshrc
    [ $? -ne 0 ] && exit 7
fi

read -p "Install vundle? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    ln -s vimrc ~/.vimrc
fi

read -p "Copy kitty config? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ln -s kitty ~/.config
fi

read -p "Copy graphic config? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ln -s xinitrc ~/.xinitrc
    ln -s i3 ~/.config
    ln -s Xresources ~/.Xresources
fi

read -p "Generate ssh-key? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh-keygen -b 4096
fi

