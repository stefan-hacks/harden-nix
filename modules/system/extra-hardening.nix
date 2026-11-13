{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.extra;
in
{
  options.hardening.extra = {
    enable = mkEnableOption "extra hardening options inspired by nix-bitcoin" // { default = false; };
  };

  options.hardening._extraServiceConfig = mkOption {
    type = types.attrs;
    readOnly = true;
    default = {};
    internal = true;
    description = "Extra hardening serviceConfig attrs merged by service modules when hardening.extra is enabled.";
  };

  config = mkIf cfg.enable {
    # When enabled, these extra options are folded into every service hardening
    # module automatically via a shared attrset that the service modules import.
    #
    # These options are more restrictive than the baseline and may break services
    # that legitimately need to see other processes, create namespaces, or use
    # non-native syscalls. Enable with care and test each service.
    hardening._extraServiceConfig = {
      ProtectProc = "invisible";
      ProcSubset = "pid";
      RestrictNamespaces = true;
      RemoveIPC = true;
      SystemCallArchitectures = "native";
    };
  };
}
