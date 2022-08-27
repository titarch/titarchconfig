#!/bin/sh
set -e

read -p "Refresh mirrors? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -S reflector
    [ $? -ne 0 ] && exit 1
    sudo reflector --verbose --country 'France' -l 10 -p https --sort rate --save /etc/pacman.d/mirrorlist
    [ $? -ne 0 ] && exit 1
fi

read -p "Install core packages? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -S git gvim curl zsh rxvt-unicode openssh python python-pip
    [ $? -ne 0 ] && exit 1
fi

read -p "Install extra packages? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -S go rofi otf-fira-sans otf-fira-mono ttf-dejavu chromium \
        feh vlc flameshot kitty playerctl pavucontrol thunar arandr pasystray \
        cmake dunst lxappearance pulseaudio sysstat pamixer acpi htop bashtop \
        awesome-terminal-fonts ttf-font-awesome otf-font-awesome iotop tig \
        papirus-icon-theme xdotool xsel xclip rofimoji qrencode rofi-calc \
        polkit-gnome alsa-utils bc
    [ $? -ne 0 ] && exit 1
fi

read -p "Install yay? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cfg_path="$PWD"
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    [ $? -ne 0 ] && exit 2
    cd yay
    makepkg -si
    [ $? -ne 0 ] && exit 3
    cd "$cfg_path"
fi

read -p "Install oh-my-zsh? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    [ $? -ne 0 ] && exit 4
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/MichaelAquilina/zsh-autoswitch-virtualenv.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/autoswitch_virtualenv
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/superbrothers/zsh-kubectl-prompt.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-kubectl-prompt
    git clone https://github.com/hanjunlee/terragrunt-oh-my-zsh-plugin ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/terragrunt
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

read -p "Install nvx? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    pip install nvx
    mkdir -p ~/.config
    ln -sf $PWD/nvx ~/.config/nvx
fi

read -p "Copy kitty config? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p ~/.config
    ln -sf $PWD/kitty ~/.config/kitty
fi

read -p "Copy graphic config? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ln -sf $PWD/xinitrc ~/.xinitrc
    mkdir -p ~/.config/i3/
    ln -sf $PWD/i3/config ~/.config/i3/config
    ln -sf $PWD/i3blocks ~/.config/i3blocks
    cp i3/background.png ~/.config/i3
    ln -sf $PWD/Xresources ~/.Xresources
    ln -sf $PWD/XCompose ~/.XCompose
    mkdir -p ~/.config/dunst/
    ln -sf $PWD/dunstrc ~/.config/dunst/dunstrc
    ln -sf $PWD/gitconfig ~/.gitconfig
    ln -sf $PWD/rofi ~/.config/rofi
    mkdir -p ~/.local/bin/
    ln -sf $PWD/nvinit ~/.local/bin/nvinit
fi

read -p "Generate ssh-key? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh-keygen -b 4096
fi

