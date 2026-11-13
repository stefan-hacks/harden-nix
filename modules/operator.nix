{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.operator;
in
{
  options.hardening.operator = {
    enable = mkEnableOption "a non-root operator user with access to hardened service client tools";

    name = mkOption {
      type = types.str;
      default = "operator";
      description = "Name of the operator user.";
    };

    groups = mkOption {
      type = with types; listOf str;
      default = [];
      description = "Extra groups of the operator user.";
    };

    allowRunAsUsers = mkOption {
      type = with types; listOf str;
      default = [];
      description = "Users as which the operator is allowed to run commands (via doas/sudo).";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.name} = {
      isNormalUser = true;
      extraGroups = [
        "systemd-journal"
        "proc" # Enable full /proc access and systemd-status
      ] ++ cfg.groups;
    };

    security = mkIf (cfg.allowRunAsUsers != []) {
      doas.extraConfig = mkIf config.security.doas.enable
        (concatMapStrings (user: "permit nopass ${cfg.name} as ${user}\n") cfg.allowRunAsUsers);

      sudo.extraConfig = mkIf (!config.security.doas.enable)
        ("${cfg.name} ALL=(${builtins.concatStringsSep "," cfg.allowRunAsUsers}) NOPASSWD: ALL\n");
    };
  };
}
