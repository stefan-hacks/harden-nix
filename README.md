# harden-nix

Pure-Nix security hardening modules for NixOS. Import this flake as a library and
enable the pieces you need.

## Quick Start

Add `harden-nix` as a flake input:

```nix
{
  inputs.harden-nix.url = "github:stefan-hacks/harden-nix";

  outputs = { self, nixpkgs, harden-nix }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        harden-nix.nixosModules.default   # or cherry-pick below
      ];
    };
  };
}
```

Then enable the baseline in your `configuration.nix`:

```nix
{
  hardening.enable = true;
}
```

## Module Reference

| Module | Path | What it does |
|--------|------|--------------|
| `hardened-baseline` | `nixosModules.default` | Enables `kernel` + `network` + `systemd-profiles` |
| `kernel` | `nixosModules.kernel` | Boot params and sysctl hardening |
| `network` | `nixosModules.network` | Firewall defaults and network sysctl |
| `systemd-profiles` | `nixosModules.systemd-profiles` | Reusable archetypes for your own services |
| `desktop-apps` | `nixosModules.desktop-apps` | Bubblewrap sandbox wrappers (opt-in) |

### Per-Service Auto-Hardening

If you import `default`, these services are automatically hardened when enabled:

| Service | Option to disable |
|---------|-------------------|
| nginx | `hardening.services.nginx.enable = false` |
| PostgreSQL | `hardening.services.postgresql.enable = false` |
| OpenSSH | `hardening.services.ssh.enable = false` |
| fail2ban | `hardening.services.fail2ban.enable = false` |
| Apache | `hardening.services.apache.enable = false` |
| Dovecot | `hardening.services.dovecot.enable = false` |
| DNSMasq | `hardening.services.dnsmasq.enable = false` |
| Mosquitto | `hardening.services.mosquitto.enable = false` |
| PHP-FPM | `hardening.services.phpFpm.enable = false` |
| Avahi | `hardening.services.avahi.enable = false` |
| NTP | `hardening.services.ntpd.enable = false` |
| Samba | `hardening.services.samba.enable = false` |
| Redis | `hardening.services.redis.enable = false` |
| MySQL/MariaDB | `hardening.services.mysql.enable = false` |

### Systemd Archetypes

Use `hardening.systemd.services.<name>` to apply a profile to any systemd unit:

```nix
{
  hardening.systemd.enable = true;
  hardening.systemd.services = {
    my-api.profile = "network-daemon";
    my-worker.profile = "local-worker";
  };
}
```

Available profiles:
- `network-daemon` — internet-facing daemon
- `local-worker` — background worker, no network
- `web-server` — HTTP service (allows `AF_UNIX`)
- `database` — database service (allows `AF_UNIX`)

## Desktop Sandboxing (Experimental)

The `desktop-apps` module replaces selected desktop packages with bubblewrap-sandboxed
wrappers. Each wrapper is generated from a flexible `makeBwrapWrapper` helper that
conditionally binds the exact resources an app needs:

- **Wayland** — `$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY`
- **X11** — `/tmp/.X11-unix`, `$DISPLAY`
- **D-Bus** — session bus (`$XDG_RUNTIME_DIR/bus`) and system bus (`/run/dbus/system_bus_socket`)
- **PipeWire / PulseAudio** — audio sockets
- **GPU** — `/dev/dri`, `/dev/kfd` (AMD), `/dev/nvidia*` (NVIDIA)
- **Fonts, icons, themes, GLib schemas**

```nix
{
  hardening.desktopApps = {
    enable = true;
    firefox.enable = true;
    chromium.enable = true;
    thunderbird.enable = true;
    discord.enable = true;
    signal.enable = true;
  };
}
```

**Caveat:** Electron apps (Discord, Signal) may self-update and need broader filesystem
access. The wrappers are starting points — audit `makeBwrapWrapper` for your specific
GPU and desktop environment.

## Why Pure-Nix Hardening Beats Runtime Profiling

Tools like [shh](https://github.com/desbma/shh) (Systemd Hardening Helper) use `strace`
to profile a service at runtime and generate the tightest possible sandbox. This is
powerful, but the generated options are **non-portable** by construction:

| shh limitation | How `harden-nix` overcomes it |
|----------------|-----------------------------|
| **Code path coverage** — misses features not exercised during profiling | We derive policy from the **service's declared intent** (its NixOS options and known data paths), not observed runtime behavior. If `services.nginx.enable = true`, we know it needs `/var/log/nginx`, `/var/cache/nginx`, and `AF_INET`. |
| **Kernel / libc / systemd version drift** | Our modules are **re-evaluated fresh** against the exact `nixpkgs` input on every build. `SystemCallFilter = "@system-service"` is a well-maintained systemd group that adapts to the host kernel. |
| **Per-system, non-composable profiles** | Every option is a Nix expression (`lib.mkDefault`, `lib.mkForce`) that composes with user overrides. No static generated files to maintain. |
| **No verification after generation** | We ship **NixOS VM tests** (`checks/`) that boot a full QEMU system with the hardening enabled and verify the service still functions. This runs on the *exact* kernel, libc, and systemd of the target NixOS release. |

The fundamental difference: `shh` is **empirical** (derive policy from observation);
`harden-nix` is **declarative** (derive policy from purpose). In a pure-Nix world,
we already know a service's configuration at evaluation time — we don't need to
observe it at runtime.

## Research Sources

- **AppArmor upstream profiles** (`gitlab.com/apparmor/apparmor`) — filesystem path
  patterns, capability requirements, and network abstractions translated into
  systemd `serviceConfig`, `CapabilityBoundingSet`, and `RestrictAddressFamilies`.
- **nixos-harden-systemd** (`github.com/thejohncrafter/nixos-harden-systemd`, NLnet
  funded) — boolean hardening options brute-forced across NixOS VM tests. Informed
  our addition of `PrivateDevices`, `PrivateMounts`, `ProtectKernelLogs`,
  `ProtectClock`, `ProtectHostname`, and `PrivateUsers` to the archetype profiles.
- **shh** (`github.com/desbma/shh`) — strace-based profiling patterns that inspired
  our understanding of what to harden, and why declarative archetypes are more
  maintainable than generated per-system profiles.

## Testing

Run the VM test suite:

```bash
nix flake check
```

Tests currently cover:
- **baselineBoots** — kernel sysctl (`ptrace_scope`, `tcp_syncookies`) verified after boot
- **nginxHardening** — nginx serves traffic with `ProtectSystem=strict` and `NoNewPrivileges=yes`
- **mosquittoHardening** — mosquitto broker starts and listens with full hardening enabled

## Design Notes

- All sysctl values are set with `lib.mkDefault` so you can override them easily.
- Where hardening values conflict with NixOS defaults, we use `mapAttrs (_: v: mkForce v)`
  to ensure the hardening module wins.
- Auto-hardening options default to `true` but only take effect when the target service is actually enabled.
- Desktop sandboxing is opt-in (`default = false` in the baseline) because it visibly changes how applications launch.
- `CapabilityBoundingSet` is explicitly declared per service (inspired by AppArmor capability rules) rather than relying on blanket defaults.

## Contributing

Add new service hardening modules under `modules/services/`. Follow the existing pattern:
- guard with `(cfg.enable && config.services.<name>.enable)`
- apply only `serviceConfig` hardening directives
- do not harden core system infrastructure (display-manager, dbus-broker, nix-daemon, etc.)
- prefer `StateDirectory`, `LogsDirectory`, `RuntimeDirectory` over bare `ReadWritePaths`
  so systemd creates the directories automatically
