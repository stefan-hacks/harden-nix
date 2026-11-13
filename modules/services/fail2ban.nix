{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.fail2ban;
in
{
  options.hardening.services.fail2ban = {
    enable = mkEnableOption "fail2ban hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.fail2ban.enable) {
    systemd.services.fail2ban.serviceConfig = {
      ProtectHome = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      LockPersonality = true;
      NoNewPrivileges = true;
    };
  };
}
