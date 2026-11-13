{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.mosquitto;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.mosquitto = {
    enable = mkEnableOption "Mosquitto hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.mosquitto.enable) {
    systemd.services.mosquitto.serviceConfig = {
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
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
      SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
      # Mosquitto needs data, logs, and runtime
      StateDirectory = "mosquitto";
      LogsDirectory = "mosquitto";
      RuntimeDirectory = "mosquitto";
      ReadWritePaths = [
        "/var/lib/mosquitto"
        "/var/log/mosquitto"
        "/run/mosquitto"
      ];
      ReadOnlyPaths = [
        "/etc/mosquitto"
      ];
      CapabilityBoundingSet = [
        "CAP_SETGID"
        "CAP_SETUID"
      ];
     } // extraHardening;
  };
}
