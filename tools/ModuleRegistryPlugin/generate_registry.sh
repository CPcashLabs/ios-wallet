#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODULE_DIR="$ROOT_DIR/modules"
OUT_FILE="$ROOT_DIR/apps/cli/AppShell/Generated/ModuleRegistry.swift"

imports=()
constructors=()

while IFS= read -r manifest_file; do
  target_name="$(basename "$(dirname "$manifest_file")")"

  manifest_type="$(sed -nE 's/.*struct[[:space:]]+([A-Za-z0-9_]+Manifest)[[:space:]]*:[[:space:]]*ModuleManifest.*/\1/p' "$manifest_file" | head -n1 || true)"

  if [[ -n "$manifest_type" ]]; then
    imports+=("import $target_name")
    constructors+=("            $manifest_type(),")
  fi

done < <(find "$MODULE_DIR" -type f -name '*Manifest.swift' | sort)

{
  echo 'import CoreRuntime'
  for line in "${imports[@]}"; do
    echo "$line"
  done
  echo
  echo 'public enum GeneratedModuleRegistry {'
  echo '    public static func all() -> [ModuleManifest] {'
  echo '        ['
  for line in "${constructors[@]}"; do
    echo "$line"
  done
  echo '        ]'
  echo '    }'
  echo '}'
} > "$OUT_FILE"

echo "Generated: $OUT_FILE"
