# TidalCycles + SuperCollider

This flake provides TidalCycles, the SuperCollider macOS app and command-line tools, and a SuperDirt starter. It supports Apple Silicon Macs running macOS 11 or later. The first `nix develop path:.` downloads the pinned SuperCollider app and builds the Tidal Haskell environment.

## One-time setup

1. From this directory, run `nix develop path:.`.
2. In that shell, run `scide` to open SuperCollider.
3. In the SuperCollider editor, evaluate this once with **Cmd+Return**:

   ```supercollider
   Quarks.install("SuperDirt");
   ```

4. Restart SuperCollider after the install completes.

## Make some sound

In one terminal, from this directory:

```sh
nix develop path:.
superdirt
```

This boots the audio server and SuperDirt using [`superdirt.scd`](superdirt.scd). Leave it running.

In a second terminal:

```sh
nix develop path:.
tidal
```

At the `tidal>` prompt, try:

```haskell
d1 $ sound "bd sn"
```

Type `hush` to stop the patterns. Press **Ctrl+C** in the SuperDirt terminal to stop the audio server.

## What Nix manages

- TidalCycles and its GHC environment are pinned by `flake.lock`.
- SuperCollider 3.14.1 is the official universal macOS app, wrapped as a Nix derivation with a pinned SHA-256 hash.
- SuperDirt is installed once through SuperCollider's Quarks system and lives in your user SuperCollider configuration.
