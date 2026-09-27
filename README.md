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
- **Hyprlock Integration**:
  - Toggle Hyprlock lock screen face unlock integration via `facelock hyprlock enable` / `disable`.
- **System & Security Tools**:
  - Restart daemon (`facelock daemon restart`).
  - View detailed system status, TPM status, and run performance benchmarks.

## Installation

```bash
omarchy plugin add https://github.com/bramvanoploo/omarchy-facelock.git --enable
```

Or manually:

```bash
mkdir -p ~/.config/omarchy/plugins/omarchy-facelock
cp -r * ~/.config/omarchy/plugins/omarchy-facelock/
omarchy-shell shell rescanPlugins
omarchy plugin enable omarchy-facelock --section right
```

## Update or remove

```bash
omarchy plugin update omarchy-facelock --yes
omarchy plugin remove omarchy-facelock --yes
```
