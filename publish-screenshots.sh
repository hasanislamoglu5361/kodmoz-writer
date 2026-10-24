#!/bin/bash
# Update README and its three screenshot assets using the authenticated GitHub CLI.
set -euo pipefail
cd "$(dirname "$0")"
repo="hasanislamoglu5361/kodmoz-writer"
gh api user --jq .login
branch=$(gh repo view "$repo" --json defaultBranchRef --jq '.defaultBranchRef.name')
if [[ -z "$branch" ]]; then
    echo 'Repository has no default branch. Publish the project with bash publish.sh first.' >&2
    exit 1
fi
upload_dir=$(mktemp -d "${TMPDIR:-/tmp}/kodmoz-screenshots.XXXXXX")
trap 'rm -rf "$upload_dir"' EXIT
for path in docs/screenshots/writing.jpg docs/screenshots/appearance.jpg docs/screenshots/links.jpg README.md; do
    # A missing file is allowed; other API failures must stop the update.
    status=0
    gh api "repos/$repo/contents/$path?ref=$branch" > "$upload_dir/current.json" 2> "$upload_dir/error.txt" || status=$?
    if [[ "$status" -ne 0 ]] && ! grep -q 'HTTP 404' "$upload_dir/error.txt"; then
        cat "$upload_dir/error.txt" >&2
        exit "$status"
    fi
    python3 - "$path" "$branch" "$upload_dir/current.json" "$upload_dir/request.json" <<'PY'
import base64, json, pathlib, sys
path, branch, current, output = sys.argv[1:]
body = {'message': 'docs: add Kodmoz Writer application screenshots', 'branch': branch,
        'content': base64.b64encode(pathlib.Path(path).read_bytes()).decode()}
try:
    metadata = json.loads(pathlib.Path(current).read_text())
except (ValueError, OSError):
    metadata = {}
if metadata.get('sha'):
    body['sha'] = metadata['sha']
pathlib.Path(output).write_text(json.dumps(body))
PY
    gh api --method PUT "repos/$repo/contents/$path" --input "$upload_dir/request.json" --jq '.content.path'
done
echo "https://github.com/$repo#ekran-görüntüleri"
