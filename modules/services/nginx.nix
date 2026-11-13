{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.nginx;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.nginx = {
    enable = mkEnableOption "nginx hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.nginx.enable) {
    systemd.services.nginx.serviceConfig = {
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
      # Allow writable logs and caches
      ReadWritePaths = [
        "/var/log/nginx"
        "/var/cache/nginx"
      ];
     } // extraHardening;
  };
}
