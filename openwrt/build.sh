#!/usr/bin/env bash
set -euo pipefail

release=${OPENWRT_RELEASE:?Set OPENWRT_RELEASE to the firmware release}
target=${OPENWRT_TARGET:?Set OPENWRT_TARGET to target/subtarget}
if [[ ! $release =~ ^[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?$ ||
      ! $target =~ ^[a-z0-9_-]+/[a-z0-9_-]+$ ]]; then
    echo 'Expected an official release (e.g. 25.12.5) and target/subtarget (e.g. mediatek/filogic).' >&2
    exit 1
fi

repo=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
work=$(mktemp -d "${RUNNER_TEMP:-/tmp}/softether-openwrt.XXXXXXXX")
sdk=$work/sdk
source_dir=$work/source
artifacts=${OPENWRT_ARTIFACT_DIR:-$repo/openwrt-artifacts}
mkdir -p "$sdk" "$source_dir" "$artifacts"

target_slug=${target/\//-}
url="https://downloads.openwrt.org/releases/$release/targets/$target"
curl --fail --silent --show-error --location --retry 3 --retry-all-errors \
    "$url/sha256sums" -o "$work/sha256sums"
sdk_prefix="openwrt-sdk-$release-${target_slug}_gcc-"
mapfile -t sdk_checksums < <(awk -v prefix="$sdk_prefix" '
    { sub(/^\*/, "", $2) }
    index($2, prefix) == 1 && $2 ~ /_musl\.Linux-x86_64\.tar\.zst$/ { print $1 "  " $2 }
' "$work/sha256sums")
if (( ${#sdk_checksums[@]} != 1 )); then
    echo "Could not find a unique 64-bit musl SDK for $release $target." >&2
    exit 1
fi
read -r sdk_hash sdk_file <<< "${sdk_checksums[0]}"
curl --fail --silent --show-error --location --retry 3 --retry-all-errors \
    "$url/$sdk_file" -o "$work/$sdk_file"
(cd "$work" && printf '%s  %s\n' "$sdk_hash" "$sdk_file" | sha256sum --check)
tar --extract --file "$work/$sdk_file" --strip-components=1 --directory "$sdk"

git -C "$repo" archive HEAD src | tar -x -C "$source_dir"
mkdir -p "$source_dir"/{tmp/objs/{Mayaqua,Cedar},tmp/as,bin/{vpnserver,vpnbridge,vpnclient,vpncmd}}
LANG=C.UTF-8 make -C "$source_dir" -j"$(nproc)" -f src/makefiles/linux_64bit_nobits.mak \
    src/bin/BuiltHamcoreFiles/unix/hamcore.se2

cp -R "$repo/openwrt/package/softethervpn" "$sdk/package/"
cd "$sdk"
sed -nE '/^src-git(-full)?( --root=package)? base / {
    s/^src-git-full /src-git /
    s,https://git\.openwrt\.org/openwrt/,https://github.com/openwrt/,
    p
}' feeds.conf.default > feeds.conf
test -s feeds.conf
./scripts/feeds update base
./scripts/feeds install libopenssl libreadline libncurses zlib

packages=(softethervpn-base softethervpn-server softethervpn-client softethervpn-bridge)
{
    printf '%s\n' '# CONFIG_ALL is not set' '# CONFIG_SIGNED_PACKAGES is not set'
    printf 'CONFIG_PACKAGE_%s=m\n' "${packages[@]}"
} > .config
make defconfig

arch=$(sed -n 's/^CONFIG_TARGET_ARCH_PACKAGES="\([^"]*\)"$/\1/p' .config)
if [[ ! $arch =~ ^aarch64_[a-z0-9_-]+$ ]]; then
    echo "Expected an OpenWrt AArch64 package architecture; got '$arch' for $target." >&2
    exit 1
fi
for package in "${packages[@]}"; do
    grep -Eq "^CONFIG_PACKAGE_$package=[my]$" .config || {
        echo "OpenWrt SDK did not select $package. Check its dependencies in the build log." >&2
        exit 1
    }
done

(
    ulimit -Sn 1024
    SOFTETHER_SOURCE_DIR="$source_dir" make -j"$(nproc)" package/softethervpn/compile V=s
)

extension=ipk
if grep -qx 'CONFIG_USE_APK=y' .config; then extension=apk; fi
shopt -s nullglob
built_packages=()
for package in "${packages[@]}"; do
    if [[ $extension == apk ]]; then
        files=(bin/packages/"$arch"/*/"${package}"-[0-9]*.apk)
    else
        files=(bin/packages/"$arch"/*/"${package}"_*_"$arch".ipk)
    fi
    if (( ${#files[@]} != 1 )); then
        echo "Expected exactly one .$extension file for $package ($arch)." >&2
        exit 1
    fi
    cp "${files[0]}" "$artifacts/"
    built_packages+=("${files[0]##*/}")
done
(
    cd "$artifacts"
    sha256sum -- "${built_packages[@]}" > SHA256SUMS
    printf 'OpenWrt: %s\nTarget: %s\nArchitecture: %s\nCommit: %s\n' \
        "$release" "$target" "$arch" "$(git -C "$repo" rev-parse HEAD)" > BUILDINFO
)
if [[ -n ${GITHUB_OUTPUT:-} ]]; then
    printf 'artifact=softethervpn-openwrt-%s-%s-%s\n' "$release" "$target_slug" "$arch" >> "$GITHUB_OUTPUT"
fi
