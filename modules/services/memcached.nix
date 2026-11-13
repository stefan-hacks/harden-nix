{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.memcached;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.memcached = {
    enable = mkEnableOption "Memcached hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.memcached.enable) {
    systemd.services.memcached.serviceConfig = {
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
        "/run/memcached"
      ];
      CapabilityBoundingSet = [ ];
     } // extraHardening;
  };
}
