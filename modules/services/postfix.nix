{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.postfix;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.postfix = {
    enable = mkEnableOption "Postfix hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.postfix.enable) {
    systemd.services.postfix.serviceConfig = {
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
      # Postfix needs its data, spool, logs, and runtime directories
      ReadWritePaths = [
        "/var/lib/postfix"
        "/var/spool/postfix"
        "/var/log/postfix"
        "/var/log/mail"
        "/run/postfix"
      ];
      ReadOnlyPaths = [
        "/etc/postfix"
        "/usr/share/postfix"
      ];
      # Postfix needs network binding (port 25) and privilege management
      CapabilityBoundingSet = [
        "CAP_CHOWN"
        "CAP_DAC_OVERRIDE"
        "CAP_DAC_READ_SEARCH"
        "CAP_KILL"
        "CAP_NET_BIND_SERVICE"
        "CAP_SETGID"
        "CAP_SETUID"
      ];
     } // extraHardening;
  };
}
