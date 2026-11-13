{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.dnsmasq;
in
{
  options.hardening.services.dnsmasq = {
    enable = mkEnableOption "dnsmasq hardening" // { default = true; };
  };

  config = mkIf (cfg.enable && config.services.dnsmasq.enable) {
    systemd.services.dnsmasq.serviceConfig = {
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
      # dnsmasq needs its config, runtime files, and potentially TFTP dirs
      ReadWritePaths = [
        "/var/lib/misc"
        "/var/run/dnsmasq"
        "/run/dnsmasq"
        "/run/libvirt"
        "/var/lib/libvirt"
        "/run/NetworkManager"
      ];
      ReadOnlyPaths = [
        "/etc/dnsmasq.conf"
        "/etc/dnsmasq.d"
        "/etc/ethers"
        "/usr/share/dnsmasq"
      ];
      # dnsmasq needs raw sockets for DHCP ping checks and net_admin for DHCP
      CapabilityBoundingSet = [
        "CAP_CHOWN"
        "CAP_DAC_OVERRIDE"
        "CAP_NET_ADMIN"
        "CAP_NET_BIND_SERVICE"
        "CAP_NET_RAW"
        "CAP_SETGID"
        "CAP_SETUID"
      ];
    };
  };
}
