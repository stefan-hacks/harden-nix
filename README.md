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

The `desktop-apps` module provides basic bubblewrap wrappers. They are **starting points**;
real desktop apps need additional binds for Wayland/X11, GPU, D-Bus, PipeWire, etc.

```nix
{
  hardening.desktopApps = {
    enable = true;
    firefox.enable = true;
  };
}
```

## Testing

Run the VM test suite:

```bash
nix flake check
```

## Design Notes

- All sysctl values are set with `lib.mkDefault` so you can override them easily.
- Auto-hardening options default to `true` but only take effect when the target service is actually enabled.
- Desktop sandboxing is opt-in (`default = false`) because it visibly changes how applications launch.

## Contributing

Add new service hardening modules under `modules/services/`. Follow the existing pattern:
- guard with `(cfg.enable && config.services.<name>.enable)`
- apply only `serviceConfig` hardening directives
- do not harden core system infrastructure (display-manager, dbus-broker, nix-daemon, etc.)
