{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.network;
in
{
  options.hardening.network = {
    enable = mkEnableOption "network-level hardening (sysctl, firewall defaults)";

    sysctl = mkOption {
      type = types.attrsOf types.int;
      default = {
        # SYN flood protection
        "net.ipv4.tcp_syncookies" = 1;

        # Reverse path filtering
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.all.rp_filter" = 1;

        # Ignore ICMP redirects
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;

        # Ignore source routed packets
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;

        # Log suspicious packets
        "net.ipv4.conf.all.log_martians" = 1;
        "net.ipv4.conf.default.log_martians" = 1;

        # Disable IPv6 router solicitations by default
        "net.ipv6.conf.default.router_solicitations" = 0;

        # Ignore ICMP echo requests to broadcast/multicast
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;

        # Ignore bogus ICMP errors
        "net.ipv4.icmp_ignore_bogus_error_responses" = 1;

        # Disable TCP timestamps (reduces idle clock fingerprinting)
        "net.ipv4.tcp_timestamps" = 0;
      };
      description = "Network sysctl values applied when network hardening is enabled.";
    };
  };

  config = mkIf cfg.enable {
    # Apply hardening sysctl values with elevated priority so they override
    # NixOS defaults that may set the same keys.
    boot.kernel.sysctl = mapAttrs (_: v: mkForce v) cfg.sysctl;

    networking.firewall = {
      enable = mkDefault true;
      logReversePathDrops = mkDefault true;
    };
  };
}
