{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.caddy;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.caddy = {
    enable = mkEnableOption "Caddy hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.caddy.enable) {
    systemd.services.caddy.serviceConfig = {
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
      CapabilityBoundingSet = [
        "CAP_NET_BIND_SERVICE"
      ];
      ReadWritePaths = [
        "/var/lib/caddy"
        "/var/log/caddy"
      ];
      ReadOnlyPaths = [
        "/etc/caddy"
      ];
     } // extraHardening;
  };
}
