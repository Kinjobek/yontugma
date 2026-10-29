#!/bin/bash
# YonTugma.app ni yig'ish: bash build.sh
set -e
cd "$(dirname "$0")"
APP=YonTugma.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>uz.sarvarbek.yontugma</string>
  <key>CFBundleName</key><string>YonTugma</string>
  <key>CFBundleDisplayName</key><string>YonTugma</string>
  <key>CFBundleExecutable</key><string>YonTugma</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHumanReadableCopyright</key><string>© 2026 Sarvarbek Nazarov — ALHARITM</string>
</dict></plist>
PLIST
# Apple Silicon (arm64) va Intel (x86_64) uchun alohida yig'ib, bitta universal faylga birlashtiramiz
for ARCH in arm64 x86_64; do
  swiftc -O -swift-version 5 -target $ARCH-apple-macos13.0 \
    -framework AppKit -framework ServiceManagement \
    -o "/tmp/YonTugma-$ARCH" main.swift
done
lipo -create /tmp/YonTugma-arm64 /tmp/YonTugma-x86_64 -output "$APP/Contents/MacOS/YonTugma"
rm -f /tmp/YonTugma-arm64 /tmp/YonTugma-x86_64
codesign --force --sign - --identifier uz.sarvarbek.yontugma "$APP"
echo "Tayyor: $(pwd)/$APP"
