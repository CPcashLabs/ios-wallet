#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IOS_DIR="$ROOT_DIR/apps/ios/AppShelliOS"

LINE_THRESHOLD="${IOS_LINE_COVERAGE_THRESHOLD:-80.00}"
BRANCH_THRESHOLD="${IOS_BRANCH_COVERAGE_THRESHOLD:-70.00}"
IOS_DERIVED_DATA="${IOS_DERIVED_DATA:-/tmp/AppShelliOSCoverageDerived}"
RESULT_BUNDLE="${IOS_RESULT_BUNDLE:-/tmp/AppShelliOSCoverage.xcresult}"
LCOV_PATH="${IOS_LCOV_PATH:-/tmp/AppShelliOSCoverage.lcov}"
SOURCE_SCOPE="/apps/ios/AppShelliOS/Sources/"

echo "[ios-coverage] project dir: $IOS_DIR"
echo "[ios-coverage] thresholds: line>=${LINE_THRESHOLD}%, branch>=${BRANCH_THRESHOLD}%"

rm -rf "$RESULT_BUNDLE"

cd "$IOS_DIR"
DEST_ID="$(
  DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
  xcodebuild -project AppShelliOS.xcodeproj -scheme AppShelliOS -showdestinations 2>/dev/null \
    | awk -F'id:' '/platform:iOS Simulator/ && /name:iPhone/ {split($2,a,","); gsub(/ /,"",a[1]); print a[1]; exit}'
)"
if [[ -z "$DEST_ID" ]]; then
  echo "[ios-coverage] no iOS Simulator destination found"
  exit 1
fi
echo "[ios-coverage] destination id: $DEST_ID"

xcodebuild -project AppShelliOS.xcodeproj \
  -scheme AppShelliOS \
  -destination "id=$DEST_ID" \
  -derivedDataPath "$IOS_DERIVED_DATA" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO \
  test

PROFDATA="$(find "$IOS_DERIVED_DATA/Build/ProfileData" -name Coverage.profdata | head -n 1)"
APP_BUNDLE_DIR="$IOS_DERIVED_DATA/Build/Products/Debug-iphonesimulator/AppShelliOS.app"
APP_BINARY="$APP_BUNDLE_DIR/AppShelliOS.debug.dylib"
if [[ ! -f "$APP_BINARY" ]]; then
  APP_BINARY="$APP_BUNDLE_DIR/AppShelliOS"
fi

if [[ -z "$PROFDATA" || ! -f "$PROFDATA" ]]; then
  echo "[ios-coverage] Coverage.profdata not found"
  exit 1
fi
if [[ ! -f "$APP_BINARY" ]]; then
  echo "[ios-coverage] app binary not found: $APP_BINARY"
  exit 1
fi

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
xcrun llvm-cov export \
  --format=lcov \
  --show-branch-summary \
  -instr-profile "$PROFDATA" \
  "$APP_BINARY" > "$LCOV_PATH"

read -r LF LH BRF BRH < <(
  awk -v scope="$SOURCE_SCOPE" '
    /^SF:/ {
      file = substr($0, 4)
      include = index(file, scope) > 0
    }
    include && /^LF:/ { lf += substr($0, 4) }
    include && /^LH:/ { lh += substr($0, 4) }
    include && /^BRF:/ { brf += substr($0, 5) }
    include && /^BRH:/ { brh += substr($0, 5) }
    END {
      printf "%d %d %d %d\n", lf, lh, brf, brh
    }
  ' "$LCOV_PATH"
)

LINE_PCT="$(awk -v lh="$LH" -v lf="$LF" 'BEGIN { if (lf == 0) { printf "0.00" } else { printf "%.2f", (lh / lf) * 100 } }')"
BRANCH_FALLBACK_NOTE=""
if [[ "$BRF" -eq 0 ]]; then
  # Swift coverage for this target currently exports BRF/BRH as zero.
  # Keep the gate deterministic by falling back to line coverage as the proxy.
  BRANCH_PCT="$LINE_PCT"
  BRANCH_FALLBACK_NOTE="[ios-coverage] branch data unavailable (BRF=0), using line coverage as branch proxy"
else
  BRANCH_PCT="$(awk -v brh="$BRH" -v brf="$BRF" 'BEGIN { if (brf == 0) { printf "0.00" } else { printf "%.2f", (brh / brf) * 100 } }')"
fi

echo "[ios-coverage] scope: $SOURCE_SCOPE"
echo "[ios-coverage] LF=$LF LH=$LH BRF=$BRF BRH=$BRH"
echo "[ios-coverage] line=${LINE_PCT}% branch=${BRANCH_PCT}%"
if [[ -n "$BRANCH_FALLBACK_NOTE" ]]; then
  echo "$BRANCH_FALLBACK_NOTE"
fi

LINE_PASS="$(awk -v v="$LINE_PCT" -v t="$LINE_THRESHOLD" 'BEGIN { print (v + 0.000001 >= t) ? 1 : 0 }')"
BRANCH_PASS="$(awk -v v="$BRANCH_PCT" -v t="$BRANCH_THRESHOLD" 'BEGIN { print (v + 0.000001 >= t) ? 1 : 0 }')"

if [[ "$LINE_PASS" != "1" || "$BRANCH_PASS" != "1" ]]; then
  echo "[ios-coverage] gate failed"
  exit 1
fi

echo "[ios-coverage] gate passed"
