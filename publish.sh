#!/bin/bash
# Publish only the reviewed source allowlist and the built app using GitHub CLI.
set -euo pipefail
cd "$(dirname "$0")"
repo="hasanislamoglu5361/kodmoz-writer"
tag="v1.2.0"
gh api user --jq .login
bash build-app.sh
gh auth setup-git
publish_workspace=$(mktemp -d "$PWD/.build/publish-work.XXXXXX")
gh repo clone "$repo" "$publish_workspace/source"
for item in Package.swift main.swift build-app.sh publish.sh publish-screenshots.sh README.md RELEASE_NOTES.md .gitignore AppIcon.png AppIcon.icns; do
    cp "$item" "$publish_workspace/source/$item"
done
mkdir -p "$publish_workspace/source/docs/screenshots"
cp docs/screenshots/*.jpg "$publish_workspace/source/docs/screenshots/"
(
    cd "$publish_workspace/source"
    if git rev-parse --verify HEAD >/dev/null 2>&1; then
        git checkout main
    else
        git checkout -B main
    fi
    git add Package.swift main.swift build-app.sh publish.sh publish-screenshots.sh README.md RELEASE_NOTES.md .gitignore AppIcon.png AppIcon.icns docs/screenshots
    if ! git diff --cached --quiet; then
        git -c user.name='Hasan İslamoğlu' -c user.email='hasanislamoglu5361@users.noreply.github.com' commit -m 'Release Kodmoz Writer 1.2: note deletion, dates and sorting'
    fi
    if git rev-parse "$tag" >/dev/null 2>&1 && [[ "$(git rev-parse "$tag^{commit}")" != "$(git rev-parse HEAD)" ]]; then
        echo "Tag $tag already points to another commit. Choose a new release version; the existing tag was preserved." >&2
        exit 1
    fi
    git push -u origin main
    if ! git rev-parse "$tag" >/dev/null 2>&1; then git tag "$tag"; fi
    git push origin "$tag"
)
ditto -c -k --sequesterRsrc --keepParent 'dist/Kodmoz Writer.app' dist/Kodmoz-Writer-macOS-arm64.zip
if gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
    gh release upload "$tag" dist/Kodmoz-Writer-macOS-arm64.zip --repo "$repo" --clobber
else
    gh release create "$tag" dist/Kodmoz-Writer-macOS-arm64.zip --repo "$repo" --title 'Kodmoz Writer 1.2' --notes-file RELEASE_NOTES.md --latest
fi
gh release view "$tag" --repo "$repo" --json url --jq .url
