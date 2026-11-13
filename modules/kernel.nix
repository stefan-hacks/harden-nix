{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.kernel;
in
{
  options.hardening.kernel = {
    enable = mkEnableOption "kernel-level hardening (sysctl, boot params)";

    sysctl = mkOption {
      type = types.attrsOf types.int;
      default = {
        # Restrict ptrace to parent/children and CAP_SYS_PTRACE
        "kernel.yama.ptrace_scope" = 2;

        # Disable unprivileged BPF by default
        "kernel.unprivileged_bpf_disabled" = 1;

        # Hide kernel pointers from non-root
        "kernel.kptr_restrict" = 2;

        # Restrict dmesg to root
        "kernel.dmesg_restrict" = 1;

        # Disable core dumps of setuid binaries
        "fs.suid_dumpable" = 0;

        # Follow symlinks / hardlinks only when owner matches
        "fs.protected_symlinks" = 1;
        "fs.protected_hardlinks" = 1;

        # Increase ASLR entropy
        "vm.mmap_rnd_bits" = 32;
        "vm.mmap_rnd_compat_bits" = 16;
      };
      description = "Sysctl values applied when kernel hardening is enabled.";
    };
  };

  config = mkIf cfg.enable {
    # Boot-time mitigations
    boot.kernelParams = [
      "slab_nomerge"
      "init_on_alloc=1"
      "init_on_free=1"
      "page_alloc_shuffle=1"
      "randomize_kstack_offset=on"
      "vsyscall=none"
      "debugfs=off"
    ];

    # Apply hardening sysctl values with elevated priority so they override
    # NixOS defaults that may set the same keys.
    boot.kernel.sysctl = mapAttrs (_: v: mkForce v) cfg.sysctl;
  };
}
