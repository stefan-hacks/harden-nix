{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.redis;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.redis = {
    enable = mkEnableOption "Redis hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.redis.servers != {}) {
    # Redis creates one systemd service per server named redis-<name>.service
    systemd.services = mapAttrs' (srvName: srvCfg:
      nameValuePair "redis-${srvName}" {
        serviceConfig = {
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
          # Redis needs its data directory and log
          ReadWritePaths = [
            "/var/lib/redis"
            "/var/log/redis"
            "/run/redis"
          ];
          ReadOnlyPaths = [
            "/etc/redis"
          ];
          CapabilityBoundingSet = [
            "CAP_SETGID"
            "CAP_SETUID"
          ];
         } // extraHardening;
      }
    ) config.services.redis.servers;
  };
}
