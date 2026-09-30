# Omarchy Facelock Bar Plugin

An [Omarchy](https://omarchy.org) status bar plugin to install, configure, and manage [Facelock](https://github.com/tyvsmith/facelock) biometric face authentication.

![preview](https://github.com/bramvanoploo/omarchy-facelock/blob/main/preview.png?raw=true)

## Features

- **Installation Check**: Detects whether `facelock-bin` or `facelock` is installed. Offers a one-click button to install via `yay -S facelock-bin`.
- **Interactive Setup Wizard**: One-click launcher for `facelock setup` inside Omarchy's styled floating presentation terminal.
- **Biometric Face Enrollment & Testing**:
  - `facelock enroll`: Capture and train face models.
  - `facelock test`: Test real-time recognition.
  - Model management: List and clear enrolled faces.
- **Camera & Live Preview**:
  - `facelock preview`: Graphical face detection and recognition preview window.
  - `facelock devices`: List attached V4L2 cameras and IR capability.
- **Hyprlock & Lock Screen Support**:
  - Toggle Hyprlock lock screen face unlock integration via `facelock hyprlock enable` / `disable`.
  - Add or remove face unlock support for the Lock Screen Explorer plugin (`/etc/pam.d/omarchy-lock-face`).
- **Hardware & IR Detection**:
  - Automatic hardware detection for infrared (IR) cameras.
  - One-click toggle for `require_ir` in `/etc/facelock/config.toml` (automatically manages `abort_if_ssh = false` under `[security]` when disabled).
- **System & Security Tools**:
  - Quick access to edit `/etc/facelock/config.toml` in your configured system editor.
  - Restart daemon (`facelock daemon restart`).
  - View detailed system status, TPM status, and run performance benchmarks.
  - Complete uninstall flow with PAM and face model cleanup.

## Non-IR Cameras & Lock Screen Explorer (T2 MacBooks)

On computers without an infrared camera—such as Apple T2 MacBooks and laptops equipped with standard RGB webcams—setting `abort_if_ssh = false` under the `[security]` section in `/etc/facelock/config.toml` is required to get face unlock working reliably with the **Lock Screen Explorer** plugin.

Without `abort_if_ssh = false`, Facelock's caller session provenance checks can reject authentication attempts from the lock screen on these systems. This plugin manages this setting automatically:
- Disabling the IR camera requirement (`require_ir = false`) automatically adds or sets `abort_if_ssh = false` in `/etc/facelock/config.toml` and restarts `facelock-daemon.service`.
- Re-enabling the IR requirement automatically removes `abort_if_ssh` and its value, restoring Facelock's default secure posture.

## Installation

```bash
omarchy plugin add https://github.com/bramvanoploo/omarchy-facelock.git --enable
```

Or manually:

```bash
mkdir -p ~/.config/omarchy/plugins/bramvanoploo.omarchy-facelock
cp -r * ~/.config/omarchy/plugins/bramvanoploo.omarchy-facelock/
omarchy-shell shell rescanPlugins
omarchy plugin enable bramvanoploo.omarchy-facelock --section right
```

## Update or remove

```bash
omarchy plugin update bramvanoploo.omarchy-facelock --yes
omarchy plugin remove bramvanoploo.omarchy-facelock --yes
```
