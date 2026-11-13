{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.minio;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.minio = {
    enable = mkEnableOption "MinIO hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.minio.enable) {
    systemd.services.minio.serviceConfig = {
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
      # MinIO needs its data store, logs, and runtime
      ReadWritePaths = [
        "/var/lib/minio"
        "/var/log/minio"
        "/run/minio"
      ];
      ReadOnlyPaths = [
        "/etc/minio"
      ];
      CapabilityBoundingSet = [
        "CAP_SETGID"
        "CAP_SETUID"
      ];
     } // extraHardening;
  };
}
