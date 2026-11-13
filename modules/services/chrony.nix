{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.chrony;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.chrony = {
    enable = mkEnableOption "chrony hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.chrony.enable) {
    systemd.services.chronyd.serviceConfig = {
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
        config.services.chrony.directory
      ];
      ReadOnlyPaths = [
        "/etc/chrony.conf"
        "/usr/share/chrony"
      ];
      CapabilityBoundingSet = [
        "CAP_CHOWN"
        "CAP_DAC_OVERRIDE"
        "CAP_NET_BIND_SERVICE"
        "CAP_SETGID"
        "CAP_SETUID"
        "CAP_SYS_RESOURCE"
        "CAP_SYS_TIME"
      ];
     } // extraHardening;
  };
}
