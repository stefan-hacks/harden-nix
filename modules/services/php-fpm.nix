{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.phpFpm;
in
{
  options.hardening.services.phpFpm = {
    enable = mkEnableOption "PHP-FPM hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.phpfpm.pools != {}) {
    # PHP-FPM creates one systemd service per pool named phpfpm-<name>.service
    # We iterate over configured pools and harden each service.
    systemd.services = mapAttrs' (poolName: poolCfg:
      nameValuePair "phpfpm-${poolName}" {
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
          # PHP-FPM needs web roots, sockets, and log dirs
          ReadWritePaths = [
            "/var/log/php-fpm"
            "/run/php-fpm"
            "/run/php"
            "/var/tmp"
          ];
          ReadOnlyPaths = [
            "/etc/php"
          ];
          # PHP-FPM drops privileges to pool user; needs setuid/setgid/chown
          CapabilityBoundingSet = [
            "CAP_CHOWN"
            "CAP_DAC_OVERRIDE"
            "CAP_KILL"
            "CAP_NET_ADMIN"
            "CAP_SETGID"
            "CAP_SETUID"
          ];
        };
      }
    ) config.services.phpfpm.pools;
  };
}
