#!/usr/bin/env bash
set -eo pipefail

PLUGIN_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$HOME/.config/omarchy/plugins/omarchy-facelock"

echo "Validating plugin..."
omarchy-plugin-validate "$PLUGIN_SRC"

echo "Installing plugin to $TARGET_DIR..."
mkdir -p "$TARGET_DIR"
cp -r "$PLUGIN_SRC/manifest.json" "$TARGET_DIR/"
cp -r "$PLUGIN_SRC/BarWidget.qml" "$TARGET_DIR/"
cp -r "$PLUGIN_SRC/FacelockModel.js" "$TARGET_DIR/"
cp -r "$PLUGIN_SRC/README.md" "$TARGET_DIR/"
mkdir -p "$TARGET_DIR/scripts"
cp -r "$PLUGIN_SRC/scripts/facelock-helper" "$TARGET_DIR/scripts/"
chmod +x "$TARGET_DIR/scripts/facelock-helper"

echo "Rescanning Omarchy plugins..."
omarchy-shell shell rescanPlugins
sleep 1

echo "Enabling omarchy-facelock widget on the right bar..."
omarchy plugin enable omarchy-facelock --section right || true

echo "Facelock plugin installed and enabled successfully!"
