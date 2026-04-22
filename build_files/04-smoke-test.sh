#!/usr/bin/env bash
# Smoke test — catch silent Arch failures before the image ships.
# Runs before finalize so pacman DB, /build, and full FS are still intact.

echo "::group::===========================> Smoke test"

set -oue pipefail

ERRORS=0
fail() { echo "FAIL: $*" >&2; ERRORS=$((ERRORS + 1)); }

# ── 1. Shared library cache ────────────────────────────────────────────────
echo "-- ldconfig"
BAD_LDCONFIG=$(ldconfig 2>&1 | grep -Ei "error|cannot open" || true)
[[ -z "$BAD_LDCONFIG" ]] || fail "ldconfig errors: $BAD_LDCONFIG"

# ── 2. Key binary ldd checks (missing .so = silent runtime crash) ──────────
echo "-- shared library deps"
for bin in /usr/bin/niri /usr/bin/alacritty /usr/bin/kitty /usr/bin/fuzzel \
           /usr/bin/gtkgreet /usr/bin/cage; do
    [[ -f "$bin" ]] || { fail "Binary missing: $bin"; continue; }
    MISSING=$(ldd "$bin" 2>/dev/null | grep "not found" || true)
    [[ -z "$MISSING" ]] || fail "$bin has missing .so deps: $MISSING"
done

# ── 3. Pacman file integrity ───────────────────────────────────────────────
echo "-- pacman file integrity"
MISSING_FILES=$(pacman -Qk 2>&1 | grep 'missing files' | grep -v ', 0 missing files' || true)
[[ -z "$MISSING_FILES" ]] || fail "Packages with missing files: $MISSING_FILES"

# ── 4. No config file conflicts left unresolved ───────────────────────────
echo "-- pacnew conflicts"
PACNEW=$(find /etc -name "*.pacnew" -o -name "*.pacsave" 2>/dev/null || true)
[[ -z "$PACNEW" ]] || fail "Unresolved pacman config conflicts: $PACNEW"

# ── 5. No broken symlinks in critical paths ────────────────────────────────
echo "-- broken symlinks"
BROKEN=$(find /usr/bin /usr/lib /etc -xtype l -not -path '/usr/lib/bootc/*' 2>/dev/null | head -10 || true)
[[ -z "$BROKEN" ]] || fail "Broken symlinks: $BROKEN"

# ── 6. Key runtime binaries present ───────────────────────────────────────
echo "-- key binaries"
for bin in niri greetd gtkgreet cage fuzzel alacritty kitty yazi nemo \
           cliphist wl-copy flatpak chezmoi just sjust keyd; do
    command -v "$bin" &>/dev/null || fail "Missing from PATH: $bin"
done

# ── 7. Helper scripts are executable ──────────────────────────────────────
echo "-- script permissions"
for s in /usr/bin/sjust /usr/bin/cliphist-pick /usr/bin/cliphist-preview \
          /usr/bin/niri-nav /usr/bin/niri-minimap /usr/bin/smart-close.sh \
          /usr/bin/niri-tile-toggle /usr/bin/niri-complement-column; do
    [[ -x "$s" ]] || fail "Not executable: $s"
done

# ── 8. Build tools are absent (compiler cleanup verification) ─────────────
echo "-- build tool cleanup"
command -v gcc &>/dev/null && fail "gcc remains in image — orphan cleanup failed" || true

# ── 9. Systemd unit files parse cleanly ───────────────────────────────────
echo "-- systemd unit validity"
while read -r line; do
    fail "systemd-analyze: $line"
done < <(systemd-analyze verify \
    /usr/lib/systemd/system/greetd.service \
    /usr/lib/systemd/system/uupd.service \
    /usr/lib/systemd/system/keyd.service \
    2>&1 | grep -Ei "error|failed" | head -20 || true)

# ── result ─────────────────────────────────────────────────────────────────
echo ""
echo "Smoke test: $ERRORS error(s)"
[[ "$ERRORS" -eq 0 ]] || exit 1

echo "::endgroup::"
