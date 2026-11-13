{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.nextcloud;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.nextcloud = {
    enable = mkEnableOption "Nextcloud hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.nextcloud.enable) {
    # Nextcloud uses a setup service and a cron service;
    # the web runtime is handled by the web server / PHP-FPM.
    systemd.services = {
      nextcloud-setup.serviceConfig = {
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
        MemoryDenyWriteExecute = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
        ReadWritePaths = [
          "/var/lib/nextcloud"
          "/var/log/nextcloud"
        ];
        ReadOnlyPaths = [
          "/etc/nextcloud"
        ];
        CapabilityBoundingSet = [
          "CAP_SETGID"
          "CAP_SETUID"
        ];
       } // extraHardening;

      nextcloud-cron.serviceConfig = {
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
        MemoryDenyWriteExecute = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
        ReadWritePaths = [
          "/var/lib/nextcloud"
          "/var/log/nextcloud"
        ];
        ReadOnlyPaths = [
          "/etc/nextcloud"
        ];
        CapabilityBoundingSet = [
          "CAP_SETGID"
          "CAP_SETUID"
        ];
       } // extraHardening;
    };
  };
}
