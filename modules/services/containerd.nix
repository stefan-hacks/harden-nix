{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.containerd;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false) config.hardening._extraServiceConfig;
in
{
  options.hardening.services.containerd = {
    enable = mkEnableOption "containerd hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.virtualisation.containerd.enable) {
    systemd.services.containerd.serviceConfig = {
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      # containerd manages cgroups for containers; it needs write access.
      ProtectControlGroups = false;
      RestrictRealtime = true;
      # containerd extracts images that may contain setuid binaries.
      RestrictSUIDSGID = false;
      LockPersonality = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" "AF_PACKET" ];
      # containerd needs mount and privileged syscalls for runtime management.
      SystemCallFilter = [ "@system-service" ];
      ReadWritePaths = [
        "/var/lib/containerd"
        "/var/log/containerd"
        "/run/containerd"
      ];
      ReadOnlyPaths = [
        "/etc/containerd"
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
