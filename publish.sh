#!/bin/bash
# Publish only the reviewed source allowlist and the built app using GitHub CLI.
set -euo pipefail
cd "$(dirname "$0")"
repo="hasanislamoglu5361/kodmoz-writer"
tag="v1.1.0"
gh api user --jq .login
bash build-app.sh
mkdir -p .build/publish-source
for item in Package.swift main.swift build-app.sh publish.sh README.md RELEASE_NOTES.md .gitignore AppIcon.png AppIcon.icns; do
    cp "$item" ".build/publish-source/$item"
done
(
    cd .build/publish-source
    if [[ ! -d .git ]]; then git init -b main; fi
    git add Package.swift main.swift build-app.sh publish.sh README.md RELEASE_NOTES.md .gitignore AppIcon.png AppIcon.icns
    if ! git diff --cached --quiet; then
        git -c user.name='Hasan İslamoğlu' -c user.email='hasanislamoglu5361@users.noreply.github.com' commit -m 'Release Kodmoz Writer 1.1: immersive writing, notes and instant autosave'
    fi
    if ! git remote get-url origin >/dev/null 2>&1; then git remote add origin "https://github.com/$repo.git"; fi
    gh auth setup-git
    git push -u origin main
    if ! git rev-parse "$tag" >/dev/null 2>&1; then git tag "$tag"; fi
    git push origin "$tag"
)
ditto -c -k --sequesterRsrc --keepParent 'dist/Kodmoz Writer.app' dist/Kodmoz-Writer-macOS-arm64.zip
if gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
    gh release upload "$tag" dist/Kodmoz-Writer-macOS-arm64.zip --repo "$repo" --clobber
else
    gh release create "$tag" dist/Kodmoz-Writer-macOS-arm64.zip --repo "$repo" --title 'Kodmoz Writer 1.1' --notes-file RELEASE_NOTES.md --latest
fi
gh release view "$tag" --repo "$repo" --json url --jq .url
