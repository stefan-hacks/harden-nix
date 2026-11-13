{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.lighttpd;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.lighttpd = {
    enable = mkEnableOption "lighttpd hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.lighttpd.enable) {
    systemd.services.lighttpd.serviceConfig = {
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
        "CAP_DAC_READ_SEARCH"
      ];
      ReadWritePaths = [
        "/var/log/lighttpd"
        "/run/lighttpd"
        "/var/cache/lighttpd"
      ];
      ReadOnlyPaths = [
        "/etc/lighttpd"
      ];
     } // extraHardening;
  };
}
