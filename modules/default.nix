{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening;
in
{
  imports = [
    ./kernel.nix
    ./network.nix
    ./systemd-profiles.nix
    ./desktop-apps.nix
    ./services/nginx.nix
    ./services/postgresql.nix
    ./services/ssh.nix
    ./services/fail2ban.nix
  ];

  options.hardening = {
    enable = mkEnableOption "all hardening modules (baseline preset)";
  };

  # When the baseline preset is enabled, flip on every submodule.
  config = mkIf cfg.enable {
    hardening.kernel.enable = mkDefault true;
    hardening.network.enable = mkDefault true;
    hardening.systemd.enable = mkDefault true;
    hardening.desktopApps.enable = mkDefault false; # opt-in: changes visible desktop apps
  };
}
