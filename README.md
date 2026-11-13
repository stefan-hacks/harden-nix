# ❄️ harden-nix

> **Declarative, composable security hardening for NixOS — no AppArmor required.**

[![NixOS](https://img.shields.io/badge/NixOS-26.05-blue?logo=nixos&logoColor=white)](https://nixos.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Flakes](https://img.shields.io/badge/Nix-Flake-purple?logo=nixos)](https://nixos.wiki/wiki/Flakes)

A pure-Nix flake providing **drop-in hardening modules** for NixOS services, daemons, and desktop applications. Inspired by upstream AppArmor profiles, `nixos-harden-systemd`, and `nix-bitcoin` — implemented entirely in declarative NixOS modules with **zero runtime profiling**.

---

## ✨ Why harden-nix?

| AppArmor | harden-nix |
|---|---|
| Maintains per-binary profiles with `/nix/store` hash wildcards | Modules attach directly to `systemd.services.<name>` — no path maintenance |
| Requires binary policy compilation on target | Pure Nix evaluation — zero target-side compilation |
| Profiles can drift across releases | Tied to NixOS module system — versioned with your flake.lock |
| Desktop apps need complex abstraction stacks | Use Flatpak for desktop apps — already sandboxed, managed declaratively via nix-flatpak |

---

## 🚀 Quick Start

### Flake Input

```nix
{
  inputs.harden-nix.url = "github:stefan-hacks/harden-nix";

  outputs = { self, nixpkgs, harden-nix }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        harden-nix.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

### Enable Baseline Hardening

```nix
{ config, pkgs, ... }: {
  # System-level hardening (kernel, network, systemd archetypes)
  hardening.enable = true;

  # Pick the service profiles you need — hardening applies automatically
  # when the underlying service is enabled in your configuration.
  hardening.profiles = {
    web-server.enable = true;    # nginx, apache, caddy, lighttpd, php-fpm
    database.enable = true;        # postgresql, mysql, redis, mongodb, memcached
    mail.enable = true;            # dovecot, postfix
    messaging.enable = true;       # mosquitto, matrix-synapse
    network.enable = true;         # ssh, dns, vpn, ntp, avahi, tor
    storage.enable = true;         # samba, syncthing, nextcloud, minio
    security.enable = true;        # fail2ban, vaultwarden, crowdsec
    containers.enable = true;      # docker, containerd, podman
    logging.enable = true;         # rsyslog
    all.enable = true;             # shortcut: enable every profile above
  };

  # Declarative Flatpak apps (already sandboxed by Flatpak itself)
  # Just run `flatpak search <name>`, grab the app ID, and drop it here.
  hardening.flatpak.enable = true;
  services.flatpak.packages = [
    "org.mozilla.firefox"
    "org.chromium.Chromium"
    "com.discordapp.Discord"
    "org.telegram.desktop"
  ];

  # Opt-in strict extra hardening (may break some services — test first)
  hardening.extra.enable = false;
}
```

---

## 📦 Module Catalog

### 🔒 System Hardening

| Module | Path | Description |
|--------|------|-------------|
| **Kernel** | `modules/system/kernel.nix` | Hardened boot params + `sysctl` overrides (ptrace, ASLR, BPF, dmesg) |
| **Network** | `modules/system/network.nix` | TCP syncookies, rp_filter, ICMP hardening, firewall defaults |
| **Extra Hardening** | `modules/system/extra-hardening.nix` | Opt-in strict preset: `ProtectProc`, `RestrictNamespaces`, `RemoveIPC` |

### 🏛️ Reusable Systemd Archetypes

| Module | Path | Description |
|--------|------|-------------|
| **Systemd Profiles** | `modules/profiles/systemd-profiles.nix` | Reusable security archetypes: `network-daemon`, `local-worker`, `web-server`, `database` |

### 🌐 Web Servers

| Module | Service | Key Restrictions |
|--------|---------|-----------------|
| [nginx.nix](modules/services/nginx.nix) | `services.nginx` | `ProtectSystem=strict`, `AF_UNIX` + `AF_INET`, `CAP_NET_BIND_SERVICE` |
| [apache.nix](modules/services/apache.nix) | `services.httpd` | `ProtectSystem=strict`, `AF_UNIX` + `AF_INET`, `CAP_NET_BIND_SERVICE` + `CAP_CHOWN` |
| [caddy.nix](modules/services/caddy.nix) | `services.caddy` | `ProtectSystem=strict`, `AF_UNIX` + `AF_INET`, `CAP_NET_BIND_SERVICE` |
| [lighttpd.nix](modules/services/lighttpd.nix) | `services.lighttpd` | `ProtectSystem=strict`, `AF_UNIX` + `AF_INET`, `CAP_NET_BIND_SERVICE` |
| [php-fpm.nix](modules/services/php-fpm.nix) | `services.phpfpm` | `ProtectSystem=strict`, `AF_UNIX`, worker process isolation |

### 🗄️ Databases

| Module | Service | Key Restrictions |
|--------|---------|-----------------|
| [postgresql.nix](modules/services/postgresql.nix) | `services.postgresql` | `ProtectSystem=strict`, `AF_UNIX` + `AF_INET`, `StateDirectory` |
| [mysql.nix](modules/services/mysql.nix) | `services.mysql` | `ProtectSystem=strict`, `AF_UNIX` + `AF_INET`, `CAP_IPC_LOCK` |
| [redis.nix](modules/services/redis.nix) | `services.redis` | `ProtectSystem=strict`, `AF_UNIX` + `AF_INET`, `StateDirectory` |
| [mongodb.nix](modules/services/mongodb.nix) | `services.mongodb` | `ProtectSystem=strict`, `AF_UNIX` + `AF_INET`, `StateDirectory` |
| [memcached.nix](modules/services/memcached.nix) | `services.memcached` | `ProtectSystem=strict`, `AF_UNIX` + `AF_INET`, `StateDirectory` |

### 📧 Mail

| Module | Service | Key Restrictions |
|--------|---------|-----------------|
| [dovecot.nix](modules/services/dovecot.nix) | `services.dovecot2` | `ProtectSystem=strict`, `AF_UNIX` + `AF_INET`, `CapabilityBoundingSet` with `CAP_CHOWN` |
| [postfix.nix](modules/services/postfix.nix) | `services.postfix` | `ProtectSystem=strict`, `AF_UNIX` + `AF_INET`, `CAP_DAC_OVERRIDE` + `CAP_CHOWN` |

### 💬 Messaging

| Module | Service | Key Restrictions |
|--------|---------|-----------------|
| [mosquitto.nix](modules/services/mosquitto.nix) | `services.mosquitto` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6`, `StateDirectory` |
| [matrix-synapse.nix](modules/services/matrix-synapse.nix) | `services.matrix-synapse` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX`, `StateDirectory` |

### 🌐 Networking / DNS / VPN

| Module | Service | Key Restrictions |
|--------|---------|-----------------|
| [ssh.nix](modules/services/ssh.nix) | `services.openssh` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX`, `CAP_NET_BIND_SERVICE` + `CAP_SYS_PTRACE` |
| [dnsmasq.nix](modules/services/dnsmasq.nix) | `services.dnsmasq` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX` + `AF_NETLINK` |
| [unbound.nix](modules/services/unbound.nix) | `services.unbound` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6`, `StateDirectory` |
| [bind.nix](modules/services/bind.nix) | `services.bind` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX`, `CAP_NET_BIND_SERVICE` |
| [avahi.nix](modules/services/avahi.nix) | `services.avahi` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX` + `AF_NETLINK`, `CAP_NET_BIND_SERVICE` |
| [ntpd.nix](modules/services/ntpd.nix) | `services.ntp` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6`, `CAP_SYS_TIME` + `CAP_NET_BIND_SERVICE` |
| [chrony.nix](modules/services/chrony.nix) | `services.chrony` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6`, `CAP_SYS_TIME` + `CAP_NET_BIND_SERVICE` |
| [tor.nix](modules/services/tor.nix) | `services.tor` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX` + `AF_NETLINK`, `CAP_NET_BIND_SERVICE` |
| [wireguard.nix](modules/services/wireguard.nix) | `networking.wg-quick` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_NETLINK`, `CAP_NET_ADMIN` |
| [openvpn.nix](modules/services/openvpn.nix) | `services.openvpn` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_NETLINK` + `AF_PACKET`, `CAP_NET_ADMIN` |

### 💾 Storage / File Sharing

| Module | Service | Key Restrictions |
|--------|---------|-----------------|
| [samba.nix](modules/services/samba.nix) | `services.samba` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX` + `AF_NETLINK`, broad `CapabilityBoundingSet` |
| [syncthing.nix](modules/services/syncthing.nix) | `services.syncthing` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX`, `StateDirectory` |
| [nextcloud.nix](modules/services/nextcloud.nix) | `services.nextcloud` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX`, `StateDirectory` |
| [minio.nix](modules/services/minio.nix) | `services.minio` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX`, `StateDirectory` |

### 🛡️ Security Tools

| Module | Service | Key Restrictions |
|--------|---------|-----------------|
| [fail2ban.nix](modules/services/fail2ban.nix) | `services.fail2ban` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX` + `AF_NETLINK`, `CAP_NET_ADMIN` + `CAP_NET_RAW` |
| [vaultwarden.nix](modules/services/vaultwarden.nix) | `services.vaultwarden` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX`, `StateDirectory` |
| [crowdsec.nix](modules/services/crowdsec.nix) | `services.crowdsec` | `ProtectSystem=strict`, `AF_INET` + `AF_INET6` + `AF_UNIX`, `StateDirectory` |

### 🐳 Containers

| Module | Service | Key Restrictions |
|--------|---------|-----------------|
| [docker.nix](modules/services/docker.nix) | `virtualisation.docker` | `ProtectControlGroups=false`, `RestrictSUIDSGID=false`, broad `CapabilityBoundingSet` |
| [containerd.nix](modules/services/containerd.nix) | `virtualisation.containerd` | `ProtectControlGroups=false`, broad `CapabilityBoundingSet` |
| [podman.nix](modules/services/podman.nix) | `virtualisation.podman` | `ProtectControlGroups=false`, broad `CapabilityBoundingSet` |

### 📝 Logging

| Module | Service | Key Restrictions |
|--------|---------|-----------------|
| [rsyslog.nix](modules/services/rsyslog.nix) | `services.rsyslogd` | `ProtectSystem=strict`, `AF_UNIX` + `AF_INET`, `StateDirectory` |

### 📦 Flatpak Applications

| Module | Path | Description |
|--------|------|-------------|
| **Flatpak** | `modules/flatpak.nix` | Security-hardened defaults for nix-flatpak. Auto-imports nix-flatpak, restricts filesystem access to `xdg-download`, and enables weekly auto-updates. |

Use Flatpak for desktop apps — they are already sandboxed by Flatpak itself, so no extra hardening layer is needed. Just run `flatpak search <name>`, copy the app ID, and add it to `services.flatpak.packages`:

```nix
{
  hardening.flatpak.enable = true;

  services.flatpak.packages = [
    # Browsers
    "org.mozilla.firefox"
    "org.chromium.Chromium"
    "com.brave.Browser"

    # Communication
    "com.discordapp.Discord"
    "org.telegram.desktop"
    "im.riot.Riot"

    # Media
    "org.videolan.VLC"
    "io.mpv.Mpv"

    # Productivity
    "md.obsidian.Obsidian"
    "com.visualstudio.code"

    # Add anything else from `flatpak search ...`
  ];
}
```

**How it works:** `hardening.flatpak.enable = true` sets secure defaults (filesystem restricted to `~/Downloads`, auto-updates weekly). You manage the app list directly via nix-flatpak's standard interface.

**Migration tool:** `nix-to-flatpak` scans your installed Nix packages and finds Flatpak equivalents:

```bash
# Run from the flake
nix run github:stefan-hacks/harden-nix#nix-to-flatpak

# Or after adding the flake input
nix run .#nix-to-flatpak

# Scan specific packages
nix run .#nix-to-flatpak firefox thunderbird vlc

# JSON output for automation
nix run .#nix-to-flatpak -- --json
```

### 🔐 Security Helpers

| Module | Path | Description |
|--------|------|-------------|
| **D-Bus Hide Processes** | `modules/security/dbus-hide-processes.nix` | Restrict `GetUnitProcesses` to `proc` group (mitigates systemd info leak with `ProtectProc`) |
| **Operator User** | `modules/security/operator.nix` | Non-root operator with journal/proc access; optional `doas`/`sudo` run-as |

---

## 🏗️ Architecture

```
harden-nix/
├── flake.nix
├── README.md
├── checks/
│   └── default.nix              # NixOS VM tests for regression testing
└── modules/
    ├── default.nix              # Baseline preset — imports everything
    ├── flatpak.nix              # Declarative Flatpak management
    ├── system/
    │   ├── kernel.nix           # Boot params + sysctl hardening
    │   ├── network.nix          # Network sysctl + firewall defaults
    │   └── extra-hardening.nix  # Opt-in strict preset
    ├── profiles/
    │   └── systemd-profiles.nix # Reusable security archetypes
    ├── services/                # Per-service hardening modules
    └── security/
        ├── dbus-hide-processes.nix
        └── operator.nix
```

---

## 🔧 Usage Patterns

### Cherry-Pick Modules

Import only what you need:

```nix
{ inputs, ... }: {
  imports = [
    inputs.harden-nix.nixosModules.kernel
    (inputs.harden-nix + "/modules/services/nginx.nix")
  ];
}
```

### Profile-Based Enablement

Instead of toggling each service individually, enable a **profile**. Every service
in that profile is hardened automatically when it is enabled in your NixOS
configuration:

```nix
{
  hardening.profiles.web-server.enable = true;
  # Now nginx, apache, caddy, lighttpd, and php-fpm are hardened
  # automatically as soon as services.nginx.enable = true, etc.
}
```

Profiles available:

| Profile | Services Covered |
|---------|-----------------|
| `profiles.web-server` | nginx, apache, caddy, lighttpd, php-fpm |
| `profiles.database` | postgresql, mysql, redis, mongodb, memcached |
| `profiles.mail` | dovecot, postfix |
| `profiles.messaging` | mosquitto, matrix-synapse |
| `profiles.network` | ssh, dnsmasq, unbound, bind, avahi, ntpd, chrony, tor, wireguard, openvpn |
| `profiles.storage` | samba, syncthing, nextcloud, minio |
| `profiles.security` | fail2ban, vaultwarden, crowdsec |
| `profiles.containers` | docker, containerd, podman |
| `profiles.logging` | rsyslog |
| `profiles.all` | every profile above at once |

### Granular Per-Service Toggle

If you need finer control, override individual services after enabling a profile:

```nix
{
  hardening.profiles.web-server.enable = true;
  hardening.services.apache.enable = false;   # skip apache hardening
}
```

### Custom Systemd Archetypes

Apply a reusable profile to your own services:

```nix
{
  hardening.systemd.enable = true;
  hardening.systemd.services = {
    my-api.profile = "network-daemon";
    my-api.allowIPAddresses = "any";

    my-worker.profile = "local-worker";
    my-worker.allowIPAddresses = "local";

    my-web.profile = "web-server";
    my-db.profile = "database";
  };
}
```

---

## 🧪 Verification

Run the built-in VM tests:

```bash
nix flake check
```

Available checks:
- `baselineBoots` — verifies kernel + network hardening boot successfully
- `nginxHardening` — verifies nginx starts with sandboxing rules applied
- `mosquittoHardening` — verifies mosquitto starts and listens on port 1883

---

## 📋 Adding a New Service Module

1. Create `modules/services/<service-name>.nix`:

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardening.services.myservice;
  extraHardening = lib.optionalAttrs (config.hardening.extra.enable or false)
    config.hardening._extraServiceConfig;
in
{
  options.hardening.services.myservice = {
    enable = mkEnableOption "my service hardening" // { default = false; };
  };

  config = mkIf (cfg.enable && config.services.myservice.enable) {
    systemd.services.myservice.serviceConfig = {
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
      SystemCallFilter = [ "@system-service" "~@debug" "~@cpu-emulation" "~@obsolete" "~@reboot" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      ReadWritePaths = [ "/var/lib/myservice" ];
      UMask = "0027";
    } // extraHardening;
  };
}
```

2. Import it in `modules/default.nix`.

3. Add a VM test in `checks/default.nix` (optional but recommended).

---

## 🏠 Home Manager Integration

While `harden-nix` is primarily a NixOS flake, you can use the desktop sandboxing in Home Manager by wrapping packages:

```nix
{ pkgs, ... }:

let
  makeBwrapWrapper = pkgs.callPackage
    (builtins.fetchGit {
      url = "https://github.com/stefan-hacks/harden-nix";
      ref = "main";
    } + "/modules/desktop/default.nix")
    {};
in
{
  home.packages = [
    (makeBwrapWrapper {
      pkg = pkgs.firefox;
      homeDir = ".mozilla";
    })
  ];
}
```

> **Note:** Full Home Manager support is planned. For now, import the flake as a NixOS module.

---

## 📚 Research Sources

- **AppArmor upstream profiles** (`gitlab.com/apparmor/apparmor`) — filesystem path patterns, capability requirements, and network abstractions translated into systemd `serviceConfig`, `CapabilityBoundingSet`, and `RestrictAddressFamilies`.
- **nixos-harden-systemd** (`github.com/thejohncrafter/nixos-harden-systemd`, NLnet funded) — boolean hardening options brute-forced across NixOS VM tests.
- **shh** (`github.com/desbma/shh`) — strace-based profiling patterns that informed our declarative archetype approach.
- **nix-bitcoin** (`github.com/fort-nix/nix-bitcoin`) — Production-grade patterns: `ProtectProc`, `ProcSubset`, `RestrictNamespaces`, D-Bus hiding, operator user, netns isolation.

---

## ⚖️ License

MIT — see [LICENSE](LICENSE).

---

<p align="center">
  Built with ❄️ for the NixOS community.
</p>
