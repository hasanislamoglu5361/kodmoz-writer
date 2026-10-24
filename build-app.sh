#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build/cache .build/config .build/security
export CLANG_MODULE_CACHE_PATH="$PWD/.build/cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/cache"
swift build -c release -debug-info-format none --disable-sandbox --cache-path "$PWD/.build/cache" --config-path "$PWD/.build/config" --security-path "$PWD/.build/security"
app="$PWD/dist/Kodmoz Writer.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
if [[ -f AppIcon.icns ]]; then cp AppIcon.icns "$app/Contents/Resources/AppIcon.icns"; fi
cp .build/release/FocusWriter "$app/Contents/MacOS/FocusWriter"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>FocusWriter</string>
<key>CFBundleIdentifier</key><string>com.kodmoz.focuswriter</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleName</key><string>Kodmoz Writer</string>
<key>CFBundleDisplayName</key><string>Kodmoz Writer</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.1</string>
<key>CFBundleVersion</key><string>2</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app"
echo "$app"
