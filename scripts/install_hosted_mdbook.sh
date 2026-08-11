#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

mdbook_version='0.5.4'
asset_name="mdbook-v${mdbook_version}-x86_64-unknown-linux-gnu.tar.gz"
asset_size='4822940'
asset_sha256='3f28de05dafca9d0f2eab99c662116b0e37b89b1d96a08f8f430b9eeae958cd7'
asset_url="https://github.com/rust-lang/mdBook/releases/download/v${mdbook_version}/${asset_name}"
tool_root=".artifacts/cache/tools/mdbook/${mdbook_version}"
archive_path="${tool_root}/${asset_name}"
binary_path="${tool_root}/mdbook"

if [ "$(uname -s)" != 'Linux' ] || [ "$(uname -m)" != 'x86_64' ]; then
    printf 'install_hosted_mdbook: unsupported host %s/%s\n' \
        "$(uname -s)" "$(uname -m)" >&2
    exit 1
fi

mkdir -p "$tool_root"
curl --proto '=https' --tlsv1.2 --fail --location --retry 3 \
    --show-error --silent --output "$archive_path" "$asset_url"

actual_size=$(stat --format='%s' "$archive_path")
if [ "$actual_size" != "$asset_size" ]; then
    printf 'install_hosted_mdbook: archive size %s != expected %s\n' \
        "$actual_size" "$asset_size" >&2
    exit 1
fi

printf '%s  %s\n' "$asset_sha256" "$archive_path" | sha256sum --check --strict
tar --extract --gzip --file "$archive_path" --directory "$tool_root" mdbook

actual_version=$("$binary_path" --version)
if [ "$actual_version" != "mdbook v${mdbook_version}" ]; then
    printf 'install_hosted_mdbook: binary version %s != expected mdbook v%s\n' \
        "$actual_version" "$mdbook_version" >&2
    exit 1
fi

printf 'install_hosted_mdbook: installed %s at %s\n' \
    "$actual_version" "$binary_path"
