{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.flatpak;
in
{
  options.hardening.flatpak = {
    enable = mkEnableOption "security-hardened Flatpak defaults via nix-flatpak";
  };

  # When enabled, harden-nix sets secure defaults for the nix-flatpak module.
  # Users add/remove apps directly via `services.flatpak.packages` —
  # just run `flatpak search <name>`, copy the app ID, and drop it in the list.
  config = mkIf cfg.enable {
    assertions = [{
      assertion = config.services.flatpak.enable or false;
      message = ''
        hardening.flatpak requires services.flatpak.enable = true.
        When using harden-nix.nixosModules.default this is handled automatically.
      '';
    }];

    services.flatpak = {
      # Enable the flatpak subsystem (idempotent if already enabled)
      enable = true;

      # Security-oriented override: restrict filesystem access by default.
      # Users can override per-app via services.flatpak.overrides.settings.
      overrides.settings = {
        global."Context"."filesystems" = "xdg-download";
      };

      # Auto-update weekly so apps stay current (main benefit of flatpaks
      # over nixpkgs stable on a server/desktop mix)
      update.auto = {
        enable = true;
        onCalendar = "weekly";
      };

      # Also update on first activation after nixos-rebuild switch
      update.onActivation = true;
    };
  };
}
