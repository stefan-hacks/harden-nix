{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.unbound;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.unbound = {
    enable = mkEnableOption "unbound hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.unbound.enable) {
    systemd.services.unbound.serviceConfig = {
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
        config.services.unbound.stateDir
        "/run/unbound"
      ];
      ReadOnlyPaths = [
        "/etc/unbound"
        "/usr/share/unbound"
      ];
      CapabilityBoundingSet = [
        "CAP_NET_BIND_SERVICE"
        "CAP_NET_RAW"
      ];
     } // extraHardening;
  };
}
