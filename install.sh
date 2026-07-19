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
    sudo pacman -S git gvim curl zsh openssh python python-pip
    [ $? -ne 0 ] && exit 1
fi

read -p "Install extra packages? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo pacman -S hyprland dms-shell-hyprland xdg-desktop-portal-hyprland \
        xdg-desktop-portal-gtk qt5-wayland qt6-wayland wl-clipboard cliphist \
        grim slurp satty greetd hypridle ydotool fcitx5-im fcitx5-mozc kitty \
        networkmanager brightnessctl moonlight-qt playerctl pavucontrol thunar tumbler chezmoi jq otf-fira-sans \
        otf-fira-mono ttf-dejavu ttf-font-awesome awesome-terminal-fonts \
        feh vlc chromium qrencode rofimoji rofi wtype xclip \
        papirus-icon-theme qt6ct pamixer acpi htop iotop tig sysstat bc \
        alsa-utils pacman-contrib zoxide fzf
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

read -p "Install AUR packages (cursors, folder colors)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    yay -S catppuccin-cursors-mocha papirus-folders
    sudo papirus-folders -C violet --theme Papirus-Dark
fi

read -p "Setup DMS greeter (run this from inside a hyprland session)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    dms greeter install
    read -p "Enable auto-login + lock-on-boot (desktops only)? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        dms ipc call settings set greeterAutoLogin true
        dms greeter sync --autologin
    fi
fi

read -p "Enable netspeed bar widget (run from inside a session)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    dms ipc call plugins enable netspeed
    echo "widget placement: Settings > Dank Bar > Widgets, drag netspeed into the bar"
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

