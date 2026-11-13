{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.apache;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.apache = {
    enable = mkEnableOption "Apache httpd hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.httpd.enable) {
    systemd.services.httpd.serviceConfig = {
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
      # Apache needs its data, logs, modules, and runtime
      ReadWritePaths = [
        "/var/www"
        "/var/log/httpd"
        "/var/log/apache2"
        "/run/httpd"
        "/run/apache2"
        "/var/cache/apache2"
        "/var/cache/httpd"
      ];
      ReadOnlyPaths = [
        "/etc/httpd"
        "/etc/apache2"
        "/usr/lib/apache2"
        "/usr/share/apache2"
        "/usr/share/httpd"
      ];
      # Apache uses mod_apparmor-style hats; needs broad caps for modules
      CapabilityBoundingSet = [
        "CAP_DAC_OVERRIDE"
        "CAP_KILL"
        "CAP_NET_BIND_SERVICE"
        "CAP_SETGID"
        "CAP_SETUID"
        "CAP_SYS_TTY_CONFIG"
      ];
     } // extraHardening;
  };
}
