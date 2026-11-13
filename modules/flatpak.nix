{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.flatpak;
in
{
  options.hardening.flatpak = {
    enable = mkEnableOption "declarative Flatpak management via nix-flatpak";

    apps = mkOption {
      type = types.listOf (types.either types.str types.attrs);
      default = [];
      description = ''
        Flatpak applications to install declaratively.
        Can be plain app IDs (strings) or full attrsets accepted by nix-flatpak
        (e.g. <literal>{ appId = "..."; origin = "flathub"; }</literal>).
      '';
      example = literalExpression ''
        [
          "org.mozilla.firefox"
          "com.brave.Browser"
          { appId = "com.obsproject.Studio"; origin = "flathub"; }
        ]
      '';
    };

    remotes = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption { type = types.str; };
          location = mkOption { type = types.str; };
        };
      });
      default = [];
      description = "Additional Flatpak remotes to configure.";
    };

    filesystemAccess = mkOption {
      type = types.enum [ "none" "xdg-download" "xdg-documents" "home" "host" ];
      default = "xdg-download";
      description = ''
        Default filesystem access for Flatpak apps.
        <literal>xdg-download</literal> is the safest default (only ~/Downloads).
        Use <literal>home</literal> or <literal>host</literal> only if you trust the app
        and it genuinely needs broader filesystem access.
      '';
    };

    autoUpdate = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically update Flatpak apps weekly.";
    };

    uninstallUnmanaged = mkOption {
      type = types.bool;
      default = false;
      description = "Remove Flatpak apps not declared in this configuration.";
    };
  };

  config = mkIf cfg.enable (optionalAttrs (options ? services && options.services ? flatpak) {
    assertions = [{
      assertion = config.services.flatpak.enable or false;
      message = ''
        hardening.flatpak requires services.flatpak.enable = true.
        Add nix-flatpak.nixosModules.nix-flatpak to your system imports.
      '';
    }];

    services.flatpak = {
      packages = cfg.apps;

      remotes = cfg.remotes;

      overrides.settings = {
        global."Context"."filesystems" = cfg.filesystemAccess;
      };

      update.auto = mkIf cfg.autoUpdate {
        enable = true;
        onCalendar = "weekly";
      };

      uninstallUnmanaged = cfg.uninstallUnmanaged;
    };
  });
}
