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

read -p "Upgrade packages? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -Syu
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
        cmake lxappearance pulseaudio sysstat pamixer acpi htop bashtop \
        awesome-terminal-fonts ttf-font-awesome otf-font-awesome iotop tig \
        papirus-icon-theme xdotool xsel xclip rofimoji qrencode rofi-calc \
        polkit-gnome alsa-utils bc tumbler pacman-contrib
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
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    sudo chsh -s $(which zsh) $(id -un)
    [ $? -ne 0 ] && exit 4
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/MichaelAquilina/zsh-autoswitch-virtualenv.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/autoswitch_virtualenv
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/superbrothers/zsh-kubectl-prompt.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-kubectl-prompt
    git clone https://github.com/hanjunlee/terragrunt-oh-my-zsh-plugin ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/terragrunt
    [ $? -ne 0 ] && exit 5
fi

read -p "Install vundle? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi

read -p "Install nvx? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    pip install nvx
fi

read -p "Deploy dotfiles with chezmoi? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -S --needed chezmoi
    # Prompts for per-machine data (primary monitor, feature flags) on first
    # run; values land in ~/.config/chezmoi/chezmoi.toml. See home/.chezmoi.toml.tmpl.
    chezmoi init --apply --source "$PWD"
fi

read -p "Install Sunshine system files (streaming machines only)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "xorg.conf outputs/EDIDs are machine-specific - review system/sunshine/ first!"
    sudo system/install-system.sh
    echo "then restart X once."
fi

read -p "Import GPG public keys? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    gpg --import gpg/pub.key
    echo 9B3395420052532132F45BF7E25ADE1208174A13:6 | gpg --import-ownertrust
fi

read -p "Generate ssh-key? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh-keygen -b 4096
fi

