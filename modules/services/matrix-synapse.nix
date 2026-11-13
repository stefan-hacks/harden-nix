{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.matrix-synapse;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.matrix-synapse = {
    enable = mkEnableOption "Matrix Synapse hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.matrix-synapse.enable) {
    systemd.services.matrix-synapse.serviceConfig = {
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
      # Matrix Synapse needs its data, logs, and runtime directories
      ReadWritePaths = [
        "/var/lib/matrix-synapse"
        "/var/log/matrix-synapse"
        "/run/matrix-synapse"
      ];
      ReadOnlyPaths = [
        "/etc/matrix-synapse"
        "/usr/share/matrix-synapse"
      ];
      # Synapse is a Python network server; minimal capabilities needed
      CapabilityBoundingSet = [
        "CAP_DAC_OVERRIDE"
        "CAP_KILL"
        "CAP_NET_BIND_SERVICE"
        "CAP_SETGID"
        "CAP_SETUID"
      ];
     } // extraHardening;
  };
}
