#!/usr/bin/env bash
#
# Produces self-contained macOS app bundles that run on a machine without
# Homebrew or Qt installed.
#
# macdeployqt on its own is not enough for this project, for three reasons
# that each produced a bundle looking correct while being broken:
#
#   1. Qt comes from Homebrew's *split* formulae (qtbase, qtdeclarative, ...),
#      but a few modules macdeployqt chases -- QtSvg, QtPdf, QtVirtualKeyboard
#      -- live in formulae of their own. Without being told where to look it
#      cannot resolve them and leaves those plugins pointing outside.
#
#   2. It leaves an LC_RPATH of <brew prefix>/lib in the binaries it copies.
#      That entry is invisible to `otool -L`, so a scan of dependencies comes
#      back clean -- yet dependencies recorded as @rpath/... resolve through
#      it, and the app ends up loading a SECOND copy of Qt from Homebrew
#      beside the bundled one. Non-portable, and a stability hazard besides.
#
#   3. It modifies libraries after signing them, so the ad-hoc signature it
#      leaves behind fails `codesign --verify`.
#
# Everything below exists to close those three gaps and then to prove they
# are closed -- the verification is not decoration, it is the point. The
# script exits non-zero rather than hand back a bundle it could not confirm.
#
# Notarisation (--notarize) is bolted on as a final stage rather than folded
# into the signing above, and deliberately so. The hardened runtime that
# notarisation requires STRIPS every DYLD_* variable from the environment --
# and DYLD_PRINT_LIBRARIES is precisely the mechanism check 5 below uses to
# prove no second Qt is being loaded. Sign hardened up front and that check
# reads an empty log and reports a pass it never measured, which is the exact
# failure this script exists to prevent. So the bundle is proved first under
# an ad-hoc signature, and only then re-signed hardened for submission.
#
# Usage:  Tools/deploy-macos.sh [--build] [--no-smoke-test] [--out <dir>]
#                               [--notarize] [--identity <name>]
#                               [--keychain-profile <name>]
#                               [--entitlements <plist>]
#
# One-time credential setup for --notarize:
#
#     xcrun notarytool store-credentials silicium-notary \
#         --apple-id <your-apple-id> \
#         --team-id 3NG65ZLYW7 \
#         --password <app-specific-password>
#
# That password is an app-specific password generated at appleid.apple.com,
# NOT the Apple ID password itself. notarytool keeps it in the keychain, so
# it appears neither in this script nor in shell history afterwards.

set -euo pipefail

#
# Configuration
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
OUT_DIR="$BUILD_DIR/dist"
APPS=(silicium SiC64)

DO_BUILD=0
DO_SMOKE_TEST=1
DO_NOTARIZE=0

# Ad-hoc unless told otherwise, so the plain deploy path behaves exactly as
# it always has.
IDENTITY="${CODESIGN_IDENTITY:--}"
NOTARY_PROFILE="${NOTARY_PROFILE:-silicium-notary}"
ENTITLEMENTS=""

while [ $# -gt 0 ]; do
    case "$1" in
        --build)            DO_BUILD=1; shift ;;
        --no-smoke-test)    DO_SMOKE_TEST=0; shift ;;
        --out)              OUT_DIR="$2"; shift 2 ;;
        --notarize)         DO_NOTARIZE=1; shift ;;
        --identity)         IDENTITY="$2"; shift 2 ;;
        --keychain-profile) NOTARY_PROFILE="$2"; shift 2 ;;
        --entitlements)     ENTITLEMENTS="$2"; shift 2 ;;
        # Prints the header block above. Driven off "is it still a comment"
        # rather than a hardcoded line range, which silently went stale the
        # first time that block grew.
        -h|--help)          awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "$0"; exit 0 ;;
        *) echo "error: unknown option '$1' (try --help)" >&2; exit 2 ;;
    esac
done

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
fail() { printf '\033[31merror: %s\033[0m\n' "$*" >&2; exit 1; }

#
# Locate the tools
#

BREW_PREFIX="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"

MACDEPLOYQT="$(command -v macdeployqt || true)"
[ -n "$MACDEPLOYQT" ] || MACDEPLOYQT="$BREW_PREFIX/bin/macdeployqt"
[ -x "$MACDEPLOYQT" ] || fail "macdeployqt not found (looked in PATH and $BREW_PREFIX/bin)"

#
# Notarisation preflight
#
# Every one of these is checked before a single byte is built or copied.
# Submission is the slowest step in the script by an order of magnitude, and
# discovering a missing credential *after* it is a poor trade.
#

if [ "$DO_NOTARIZE" -eq 1 ]; then

    xcrun --find notarytool >/dev/null 2>&1 \
        || fail "notarytool not found -- needs Xcode 13 or newer (xcode-select -p: $(xcode-select -p 2>&1))"
    xcrun --find stapler >/dev/null 2>&1 \
        || fail "stapler not found -- needs a full Xcode install, not just the Command Line Tools"

    # An ad-hoc signature has nothing tying it to a developer account, so the
    # service cannot notarise it. It would be accepted for submission and
    # rejected minutes later; better to say so now.
    if [ "$IDENTITY" = "-" ]; then
        avail="$(security find-identity -v -p codesigning 2>/dev/null \
                 | sed -n 's/.*"\(Developer ID Application[^"]*\)".*/\1/p' || true)"
        avail="${avail%%$'\n'*}"
        fail "--notarize needs a Developer ID Application identity.
       Pass --identity <name>, or set CODESIGN_IDENTITY.${avail:+
       Available on this machine: \"$avail\"}"
    fi

    case "$IDENTITY" in
        "Developer ID Application"*) ;;
        # Apple Development / Mac Developer certs sign fine but are rejected
        # by the notary service; only Developer ID is distributable outside
        # the App Store.
        *) info "warning: '$IDENTITY' does not look like a Developer ID Application identity" ;;
    esac

    # Captured, then matched: piping into `grep -q` under pipefail can report
    # an identity as missing while it sits right there in the list -- see the
    # hardened-runtime check in the verification stage.
    known_ids="$(security find-identity -v -p codesigning 2>/dev/null || true)"
    case "$known_ids" in
        *"$IDENTITY"*) ;;
        *) fail "signing identity not found in keychain: $IDENTITY" ;;
    esac

    if [ -n "$ENTITLEMENTS" ] && [ ! -f "$ENTITLEMENTS" ]; then
        fail "entitlements file not found: $ENTITLEMENTS"
    fi

    xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1 \
        || fail "no stored notary credentials for profile '$NOTARY_PROFILE'.
       Create them once with:
           xcrun notarytool store-credentials $NOTARY_PROFILE \\
               --apple-id <your-apple-id> --team-id 3NG65ZLYW7 \\
               --password <app-specific-password>"
fi

#
# Build
#

if [ "$DO_BUILD" -eq 1 ]; then
    say "Building"
    ninja -C "$BUILD_DIR" || fail "build failed"
fi

for app in "${APPS[@]}"; do
    [ -d "$BUILD_DIR/Apps/bin/$app.app" ] || \
        fail "$app.app not found in $BUILD_DIR/Apps/bin -- build first, or pass --build"
done

#
# Collect the Qt library paths
#
# Derived rather than hardcoded: the module a given framework lives in, and
# its version, both change from one Homebrew upgrade to the next. Every
# qt*/lib directory is offered, and macdeployqt takes what it needs.
#

LIBPATH_ARGS=()
for dir in "$BREW_PREFIX"/opt/qt*/lib; do
    [ -d "$dir" ] && LIBPATH_ARGS+=("-libpath=$dir")
done
[ ${#LIBPATH_ARGS[@]} -gt 0 ] || fail "no Qt library directories found under $BREW_PREFIX/opt"

say "Deploying to $OUT_DIR"
info "macdeployqt:  $MACDEPLOYQT"
info "Qt lib paths: ${#LIBPATH_ARGS[@]}"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

#
# Strips every absolute rpath that points outside the bundle.
#
# System locations stay: /usr/lib and /System are present on every macOS
# install, so depending on them costs nothing. Anything else -- a Homebrew
# prefix, a path inside this source tree -- is a machine-specific escape
# hatch, and leaving it in is exactly how a bundle ends up quietly loading
# somebody else's Qt.
#
strip_foreign_rpaths()
{
    local bundle="$1" stripped=0

    while IFS= read -r bin; do

        file "$bin" 2>/dev/null | grep -q "Mach-O" || continue

        while IFS= read -r rpath; do

            case "$rpath" in
                /usr/lib*|/System/*|@*) continue ;;
                /*) ;;
                *) continue ;;
            esac

            if install_name_tool -delete_rpath "$rpath" "$bin" 2>/dev/null; then
                stripped=$((stripped + 1))
            fi

        done < <(otool -l "$bin" 2>/dev/null | awk '/LC_RPATH/{f=1} f&&/^ *path /{print $2; f=0}')

    done < <(find "$bundle" -type f)

    info "stripped $stripped foreign rpath entr$([ "$stripped" = 1 ] && echo y || echo ies)"
}

#
# Deploy each app
#

for app in "${APPS[@]}"; do

    say "$app.app"

    cp -R "$BUILD_DIR/Apps/bin/$app.app" "$OUT_DIR/"
    bundle="$OUT_DIR/$app.app"

    # Copying carries extended attributes along, and codesign refuses to sign
    # a bundle with "resource fork, Finder information, or similar detritus".
    xattr -cr "$bundle" 2>/dev/null || true

    # macdeployqt is noisy about optional Qt modules this project never
    # imports (Qt3D, QtStateMachine, ...). Those are expected; the checks at
    # the end decide whether the result is actually sound.
    info "running macdeployqt..."
    "$MACDEPLOYQT" "$bundle" \
        -qmldir="$ROOT_DIR/Apps" \
        "${LIBPATH_ARGS[@]}" \
        > "$OUT_DIR/$app-macdeployqt.log" 2>&1 || true

    strip_foreign_rpaths "$bundle"

    # Signed last: every edit above invalidates a signature made before it.
    info "signing..."
    codesign --force --deep --sign "${CODESIGN_IDENTITY:--}" "$bundle" 2>/dev/null \
        || fail "codesign failed for $app.app"
done

#
# Verify
#

say "Verifying"

failures=0

for app in "${APPS[@]}"; do

    bundle="$OUT_DIR/$app.app"
    printf '  %s\n' "$app.app"

    # 1. Qt was actually brought in
    n=$(ls "$bundle/Contents/Frameworks" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$n" -gt 0 ]; then
        printf '    ok    %s frameworks bundled\n' "$n"
    else
        printf '    FAIL  no frameworks bundled\n'; failures=$((failures + 1))
    fi

    # 2. Nothing reaches outside the bundle any more -- see strip_foreign_rpaths
    #
    # The `|| true` matters: not matching is the outcome we want, but it makes
    # grep exit non-zero, which under `set -e` would abort the subshell and
    # leave this reporting a pass it never actually measured.
    n=$(find "$bundle" -type f | while read -r f; do
            file "$f" 2>/dev/null | grep -q "Mach-O" || continue
            otool -l "$f" 2>/dev/null | grep -A2 LC_RPATH | grep -q "$BREW_PREFIX" \
                && echo x || true
        done | wc -l | tr -d ' ')
    if [ "$n" -eq 0 ]; then
        printf '    ok    no rpaths into %s\n' "$BREW_PREFIX"
    else
        printf '    FAIL  %s binaries still carry an rpath into %s\n' "$n" "$BREW_PREFIX"
        failures=$((failures + 1))
    fi

    # 3. Direct dependencies of the executable are all inside the bundle
    n=$(otool -L "$bundle/Contents/MacOS/$app" | grep -c "$BREW_PREFIX" || true)
    if [ "$n" -eq 0 ]; then
        printf '    ok    executable has no %s dependencies\n' "$BREW_PREFIX"
    else
        printf '    FAIL  executable still links %s libraries from %s\n' "$n" "$BREW_PREFIX"
        failures=$((failures + 1))
    fi

    # 4. The signature survived the rewriting
    if codesign --verify --deep --strict "$bundle" 2>/dev/null; then
        printf '    ok    signature valid\n'
    else
        printf '    FAIL  signature invalid\n'; failures=$((failures + 1))
    fi

    # 5. The one check that reflects what dyld really does. The static checks
    #    above all passed once on a bundle that was loading a second Qt from
    #    Homebrew, so this is the one that settles it.
    if [ "$DO_SMOKE_TEST" -eq 1 ]; then

        # SiC64 is normally started by the Hub with a machine to open, and
        # quits on its own without one -- so it is given a showcase here.
        # Otherwise the launch check would be measuring that, not the bundle.
        launch_args=()
        [ "$app" = "SiC64" ] && launch_args=("$ROOT_DIR/Apps/Silicium/Showcases/rink-a-dink.svm")

        log="$OUT_DIR/$app-smoke.log"
        DYLD_PRINT_LIBRARIES=1 "$bundle/Contents/MacOS/$app" "${launch_args[@]+"${launch_args[@]}"}" > "$log" 2>&1 &
        pid=$!
        sleep 6

        if kill -0 "$pid" 2>/dev/null; then
            printf '    ok    launches and stays up\n'
        else
            printf '    FAIL  exited within 6s (see %s)\n' "$log"; failures=$((failures + 1))
        fi
        kill -9 "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true

        # DYLD_PRINT_LIBRARIES emits one "dyld[pid]: <uuid> /path" line per
        # image, starting with the executable itself -- so a log without any
        # is not a clean bundle, it is a check that never ran. That happens
        # the moment the binary is signed with the hardened runtime, which
        # strips DYLD_* (and is why notarisation is staged after this point).
        # Reporting "ok" off an empty log would be worse than not looking.
        if ! grep -q 'dyld\[' "$log"; then
            printf '    FAIL  runtime library check did not run -- no dyld output in %s\n' "$log"
            printf '          (hardened runtime strips DYLD_*; this check must precede it)\n'
            failures=$((failures + 1))
        else
            n=$(grep -c "$BREW_PREFIX" "$log" || true)
            if [ "$n" -eq 0 ]; then
                printf '    ok    loaded nothing from %s at runtime\n' "$BREW_PREFIX"
            else
                printf '    FAIL  loaded %s libraries from %s at runtime:\n' "$n" "$BREW_PREFIX"
                grep -oE "$BREW_PREFIX[^ ]*" "$log" | sort -u | sed 's/^/          /' | head -10
                failures=$((failures + 1))
            fi
        fi
    fi
done

echo
if [ "$failures" -gt 0 ]; then
    fail "$failures check(s) failed -- these bundles are NOT ready to ship"
fi

#
# Notarise
#
# Only now, with the bundles proved sound, is the ad-hoc signature replaced
# by a real one. Nothing below alters what the app loads; it changes who
# vouches for it.
#

#
# Signs a bundle from the inside out, with the hardened runtime.
#
# --deep is not used, despite appearing in the ad-hoc signing above. Apple
# documents it as a convenience for local testing: it applies one set of
# entitlements to every nested binary alike, and quietly skips anything it
# does not recognise as nested code. What the notary service actually
# requires is that an inner signature be final before the signature
# enclosing it is computed -- so each piece is signed explicitly, deepest
# first, which is precisely the order `find -depth` yields.
#
sign_hardened()
{
    local bundle="$1" signed=0 item

    while IFS= read -r item; do

        # Version aliases inside frameworks. Signing through them just signs
        # the same target twice under a second name.
        if [ -L "$item" ]; then continue; fi

        # The bundle itself goes last, and with entitlements.
        if [ "$item" = "$bundle" ]; then continue; fi

        if [ -d "$item" ]; then
            case "$item" in
                *.framework|*.app|*.bundle) ;;
                *) continue ;;
            esac
        else
            # No pipe into grep here either: a SIGPIPE would read as "not
            # Mach-O" and silently skip signing a binary that needs it, which
            # surfaces only as an opaque rejection minutes later.
            case "$(file "$item" 2>/dev/null || true)" in
                *Mach-O*) ;;
                *) continue ;;
            esac
        fi

        codesign --force --timestamp --options runtime \
                 --sign "$IDENTITY" "$item" >/dev/null 2>&1 \
            || fail "codesign failed for ${item#"$bundle"/}"

        signed=$((signed + 1))

    done < <(find "$bundle" -depth)

    # Entitlements describe the running application, so they belong on the
    # app and on nothing inside it.
    local ent_args=()
    if [ -n "$ENTITLEMENTS" ]; then
        ent_args=(--entitlements "$ENTITLEMENTS")
    fi

    codesign --force --timestamp --options runtime \
             "${ent_args[@]+"${ent_args[@]}"}" \
             --sign "$IDENTITY" "$bundle" >/dev/null 2>&1 \
        || fail "codesign failed for $(basename "$bundle")"

    info "signed $signed nested item(s), then the bundle"
}

if [ "$DO_NOTARIZE" -eq 1 ]; then

    say "Re-signing (hardened runtime, timestamped)"
    info "identity: $IDENTITY"
    if [ -n "$ENTITLEMENTS" ]; then info "entitlements: $ENTITLEMENTS"; fi

    for app in "${APPS[@]}"; do
        printf '  %s\n' "$app.app"
        sign_hardened "$OUT_DIR/$app.app"
    done

    #
    # Submit
    #
    # Both apps ride in one archive. They are a pair -- the Hub cannot start
    # a machine without the backend -- and one submission means one wait
    # rather than two sequential ones.
    #
    # ditto, not zip(1): the frameworks are full of symlinks, and zip(1)
    # either follows or flattens them, producing an archive the service
    # rejects with a signature error that says nothing about the real cause.
    #

    say "Submitting to Apple"

    STAGE="$OUT_DIR/.notarize"
    ZIP="$OUT_DIR/notarize-submission.zip"
    SUBMIT_LOG="$OUT_DIR/notarize-submit.log"

    rm -rf "$STAGE" "$ZIP"
    mkdir -p "$STAGE"
    for app in "${APPS[@]}"; do
        ditto "$OUT_DIR/$app.app" "$STAGE/$app.app"
    done
    ditto -c -k --sequesterRsrc "$STAGE" "$ZIP"
    rm -rf "$STAGE"

    info "archive: $(du -h "$ZIP" | cut -f1)"
    info "profile: $NOTARY_PROFILE"
    info "this usually takes a few minutes..."

    # pipefail is set, so a notarytool failure survives the tee.
    if ! xcrun notarytool submit "$ZIP" \
              --keychain-profile "$NOTARY_PROFILE" \
              --wait 2>&1 | tee "$SUBMIT_LOG" | sed 's/^/    /'; then
        fail "notarytool submit failed (see $SUBMIT_LOG)"
    fi

    # `| head -1` would let head exit first and SIGPIPE sed, which pipefail
    # then turns into a failed assignment and set -e into an aborted script.
    # Taking the first line by parameter expansion has no such race.
    SUBMISSION_ID="$(sed -n 's/^ *id: *\([0-9a-fA-F-]\{8,\}\).*/\1/p' "$SUBMIT_LOG" || true)"
    SUBMISSION_ID="${SUBMISSION_ID%%$'\n'*}"
    NOTARY_STATUS="$(sed -n 's/^ *status: *\(.*[^ ]\) *$/\1/p' "$SUBMIT_LOG" | tail -1)"

    # "Invalid" is a completed submission that was rejected -- notarytool
    # itself exits 0 for it, so the status has to be read rather than
    # inferred from the exit code. The detail lives only in the log the
    # service keeps, which is why it is fetched here: without it a rejection
    # is a single unhelpful word.
    if [ "$NOTARY_STATUS" != "Accepted" ]; then
        if [ -n "$SUBMISSION_ID" ]; then
            xcrun notarytool log "$SUBMISSION_ID" \
                  --keychain-profile "$NOTARY_PROFILE" \
                  "$OUT_DIR/notarize-issues.json" >/dev/null 2>&1 || true
            info "issue log: $OUT_DIR/notarize-issues.json"
            sed -n 's/^ *"message" *: *"\(.*\)",\{0,1\}$/      - \1/p' \
                "$OUT_DIR/notarize-issues.json" 2>/dev/null | sort -u | head -10 || true
        fi
        fail "notarisation status: ${NOTARY_STATUS:-unknown} -- not stapling"
    fi

    info "accepted (submission $SUBMISSION_ID)"

    #
    # Staple
    #
    # Stapling attaches the ticket to the bundle itself, so the first launch
    # works on a machine that is offline or behind a firewall that blocks
    # Apple's OCSP endpoints. Without it the app is still notarised, but
    # Gatekeeper has to reach the network to find that out.
    #

    say "Stapling"

    for app in "${APPS[@]}"; do
        xcrun stapler staple "$OUT_DIR/$app.app" >/dev/null 2>&1 \
            || fail "stapler failed for $app.app"
        printf '    ok    %s.app\n' "$app"
    done

    #
    # Verify what Gatekeeper will actually conclude
    #

    say "Verifying notarisation"

    nfailures=0

    for app in "${APPS[@]}"; do

        bundle="$OUT_DIR/$app.app"
        printf '  %s\n' "$app.app"

        if codesign --verify --deep --strict "$bundle" 2>/dev/null; then
            printf '    ok    signature valid\n'
        else
            printf '    FAIL  signature invalid after stapling\n'; nfailures=$((nfailures + 1))
        fi

        # Captured whole, then matched -- deliberately NOT piped into
        # `grep -q`. grep -q exits the instant it matches, codesign is then
        # killed by SIGPIPE partway through its remaining output, and
        # `set -o pipefail` faithfully reports the pipeline as failed (141).
        # The match succeeds and the check still says FAIL. This check did
        # exactly that, on bundles Apple had already notarised -- which it
        # cannot do without this very flag. Same trap as the identity check
        # in the preflight; both are written this way for the same reason.
        cs_desc="$(codesign -d --verbose=2 "$bundle" 2>&1 || true)"
        case "$cs_desc" in
            *flags=*runtime*) printf '    ok    hardened runtime enabled\n' ;;
            *) printf '    FAIL  hardened runtime flag missing\n'; nfailures=$((nfailures + 1)) ;;
        esac

        if xcrun stapler validate "$bundle" >/dev/null 2>&1; then
            printf '    ok    ticket stapled\n'
        else
            printf '    FAIL  no valid ticket stapled\n'; nfailures=$((nfailures + 1))
        fi

        # The verdict that matters. Anything other than "Notarized Developer
        # ID" means a user double-clicking this gets a warning.
        src="$(spctl -a -t exec -vv "$bundle" 2>&1 | sed -n 's/^source=//p' || true)"
        src="${src%%$'\n'*}"
        if [ "$src" = "Notarized Developer ID" ]; then
            printf '    ok    Gatekeeper: %s\n' "$src"
        else
            printf '    FAIL  Gatekeeper: %s\n' "${src:-rejected}"; nfailures=$((nfailures + 1))
        fi

        # The hardened runtime enables library validation, which the ad-hoc
        # signature did not. That can break loading in ways nothing above
        # would show, so the launch is repeated against the finished article.
        # (DYLD_PRINT_LIBRARIES is stripped now -- the library-origin check
        # was made earlier, while it still worked.)
        if [ "$DO_SMOKE_TEST" -eq 1 ]; then

            launch_args=()
            [ "$app" = "SiC64" ] && launch_args=("$ROOT_DIR/Apps/Silicium/Showcases/rink-a-dink.svm")

            log="$OUT_DIR/$app-smoke-hardened.log"
            "$bundle/Contents/MacOS/$app" "${launch_args[@]+"${launch_args[@]}"}" > "$log" 2>&1 &
            pid=$!
            sleep 6

            if kill -0 "$pid" 2>/dev/null; then
                printf '    ok    launches hardened and stays up\n'
            else
                printf '    FAIL  exited within 6s under hardened runtime (see %s)\n' "$log"
                nfailures=$((nfailures + 1))
            fi
            kill -9 "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
    done

    echo
    if [ "$nfailures" -gt 0 ]; then
        fail "$nfailures notarisation check(s) failed -- these bundles are NOT ready to ship"
    fi

    rm -f "$ZIP"
fi

say "Done"
info "Bundles: $OUT_DIR"
du -sh "$OUT_DIR"/*.app | sed 's/^/    /'
if [ "$DO_NOTARIZE" -eq 1 ]; then
cat <<EOF

    Copy BOTH bundles to the target machine -- the Hub launches SiC64 as a
    separate process, so silicium.app alone cannot start a machine.

    Signed with "$IDENTITY", notarized and stapled. They open by
    double-click on any Mac running macOS $(sed -n 's/^set(CMAKE_OSX_DEPLOYMENT_TARGET "\(.*\)").*/\1/p' "$ROOT_DIR/CMakeLists.txt") or later --
    no quarantine flag to clear, and no right-click-Open dance.

    To confirm on the target machine before handing it out:

        spctl -a -t exec -vv /path/to/silicium.app
EOF
else
cat <<EOF

    Copy BOTH bundles to the target machine -- the Hub launches SiC64 as a
    separate process, so silicium.app alone cannot start a machine.

    They are ad-hoc signed, not notarized. On the target machine, clear the
    quarantine flag once after copying:

        xattr -dr com.apple.quarantine /path/to/silicium.app
        xattr -dr com.apple.quarantine /path/to/SiC64.app

    To produce bundles that open by double-click instead, re-run with:

        Tools/deploy-macos.sh --notarize --identity "Developer ID Application: ..."
EOF
fi
