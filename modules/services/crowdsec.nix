{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.crowdsec;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.crowdsec = {
    enable = mkEnableOption "CrowdSec hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.crowdsec.enable) {
    systemd.services.crowdsec.serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
      ReadWritePaths = [
        "/var/lib/crowdsec"
        "/var/log/crowdsec"
      ];
      ReadOnlyPaths = [
        "/etc/crowdsec"
      ];
    } // extraHardening;
  };
}
