#!/usr/bin/env bash
set -eo pipefail

PLUGIN_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_ID=$(jq -r .id "$PLUGIN_SRC/manifest.json")
TARGET_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

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
omarchy-shell -q shell rescanPlugins 2>/dev/null || true
sleep 0.5

echo "Enabling $PLUGIN_ID widget on the right bar..."
omarchy plugin enable "$PLUGIN_ID" --section right >/dev/null 2>&1 || true

echo "✓ Facelock plugin files installed successfully!"

echo "Restarting Omarchy shell..."
omarchy restart shell
