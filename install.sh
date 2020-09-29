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
    sudo pacman -S git go gvim curl zsh rofi otf-fira-sans otf-fira-mono ttf-dejavu chromium feh vlc flameshot kitty rxvt-unicode openssh playerctl pavucontrol thunar arandr pasystray
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
    git clone "https://github.com/MichaelAquilina/zsh-autoswitch-virtualenv.git" "$ZSH_CUSTOM/plugins/autoswitch_virtualenv"
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
    [ $? -ne 0 ] && exit 5
    ln -sf $PWD/zshrc ~/.zshrc
    [ $? -ne 0 ] && exit 6
    cp -r "dracula"/* ~/.oh-my-zsh/themes
    [ $? -ne 0 ] && exit 7
fi

read -p "Install vundle? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    ln -sf $PWD/vimrc ~/.vimrc
fi

read -p "Copy kitty config? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir ~/.config
    ln -sf $PWD/kitty ~/.config/kitty
fi

read -p "Copy graphic config? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ln -sf $PWD/xinitrc ~/.xinitrc
    mkdir -p ~/.config/i3/
    ln -sf $PWD/i3/config ~/.config/i3/config
    cp i3/background.png ~/.config/i3
    ln -sf $PWD/Xresources ~/.Xresources
    ln -sf $PWD/XCompose ~/.XCompose
fi

read -p "Generate ssh-key? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh-keygen -b 4096
fi

