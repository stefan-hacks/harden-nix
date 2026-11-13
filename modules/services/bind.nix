{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.bind;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.bind = {
    enable = mkEnableOption "bind hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.bind.enable) {
    systemd.services.bind.serviceConfig = {
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
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
      SystemCallFilter = [ "@system-service" "~@debug" "~@mount" ];
      ReadWritePaths = [
        config.services.bind.directory
        "/run/named"
      ];
      ReadOnlyPaths = [
        "/etc/bind"
        "/usr/share/bind"
      ];
      CapabilityBoundingSet = [
        "CAP_NET_BIND_SERVICE"
      ];
     } // extraHardening;
  };
}
