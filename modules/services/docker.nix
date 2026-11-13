{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.docker;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.docker = {
    enable = mkEnableOption "Docker daemon hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.virtualisation.docker.enable) {
    systemd.services.docker.serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      # Docker manages cgroups for containers; it needs write access.
      ProtectControlGroups = false;
      RestrictRealtime = true;
      # Docker extracts images that may contain setuid binaries.
      RestrictSUIDSGID = false;
      LockPersonality = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" "AF_PACKET" ];
      # Docker needs mount and privileged syscalls for container management.
      SystemCallFilter = [ "@system-service" ];
      ReadWritePaths = [
        "/var/lib/docker"
        "/var/log/docker"
        "/run/docker"
      ];
      ReadOnlyPaths = [
        "/etc/docker"
      ];
      CapabilityBoundingSet = [
        "CAP_AUDIT_WRITE"
        "CAP_CHOWN"
        "CAP_DAC_OVERRIDE"
        "CAP_FOWNER"
        "CAP_FSETID"
        "CAP_KILL"
        "CAP_NET_ADMIN"
        "CAP_NET_BIND_SERVICE"
        "CAP_NET_RAW"
        "CAP_SETGID"
        "CAP_SETFCAP"
        "CAP_SETPCAP"
        "CAP_SETUID"
        "CAP_SYS_ADMIN"
        "CAP_SYS_CHROOT"
        "CAP_SYS_PTRACE"
        "CAP_SYS_RESOURCE"
        "CAP_IPC_LOCK"
        "CAP_MKNOD"
        "CAP_SYS_TTY_CONFIG"
      ];
    } // extraHardening;
  };
}
