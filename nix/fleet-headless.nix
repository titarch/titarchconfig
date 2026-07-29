# titarchconfig fleet: terminal toolchain for a NixOS headless member (tinasx).
# The fleet's single source of truth for CONFIG is chezmoi (it just writes files
# into $HOME); Nix's job here is only to supply the BINARIES that the deployed
# zshrc/nvim wire up. So this module installs the CLI stack and nothing else -
# it never manages dotfile contents (that would fight chezmoi).
#
# Wire it into /etc/nixos/configuration.nix (imports list), then rebuild:
#   imports = [
#     ./hardware-configuration.nix
#     (import (builtins.fetchGit {
#       url = "https://github.com/titarch/titarchconfig";
#       ref = "master";
#     } + "/nix/fleet-headless.nix"))
#   ];
#   sudo nixos-rebuild switch
# then deploy the dotfiles once:  curl -fsSL z.pyy.fr | sh -s -- headless
# (boot.sh detects NixOS and only does the chezmoi/omz part).
{ pkgs, lib, ... }:
{
  programs.zsh.enable = lib.mkDefault true;   # box may already set this; mkDefault yields

  environment.systemPackages = with pkgs; [
    chezmoi                 # deploys + syncs the fleet dotfiles
    starship                # prompt (zshrc: eval starship init)
    zellij                  # multiplexer (zj = attach-or-create 'main')
    neovim                  # editor (fleet init.lua + lazy.nvim self-bootstrap)
    # modern CLI stack the zshrc aliases + fzf/zoxide/atuin/direnv hooks expect
    ripgrep fd bat eza zoxide fzf atuin direnv
    lazygit lazydocker delta jq   # lg / lzd / delta pager / jq
    git git-lfs                   # forgit + omz git aliases lean on these
  ];
  # forgit is sourced from an Arch path in the zshrc and simply no-ops here (guarded);
  # kube tools (kx/kn/stern/k9s) are desktop/work-only and intentionally omitted.
}
