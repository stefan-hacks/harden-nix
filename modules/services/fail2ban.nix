{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.fail2ban;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.fail2ban = {
    enable = mkEnableOption "fail2ban hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.fail2ban.enable) {
    systemd.services.fail2ban.serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      NoNewPrivileges = true;
      SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
     } // extraHardening;
  };
}
