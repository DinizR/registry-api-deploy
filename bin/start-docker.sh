#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORTO_API_SRC="${PORTO_API_SRC:-$(cd "$ROOT/../hexagonalboot-api" && pwd)}"
PORTO_API_PLUGINS_SRC="${PORTO_API_PLUGINS_SRC:-$(cd "$ROOT/../porto-api-plugins" && pwd)}"

if [ ! -f "$PORTO_API_SRC/pom.xml" ]; then
  echo "PORTO_API_SRC=$PORTO_API_SRC is not a hexagonalboot-api tree." >&2
  exit 1
fi
if [ ! -f "$PORTO_API_PLUGINS_SRC/pom.xml" ]; then
  echo "PORTO_API_PLUGINS_SRC=$PORTO_API_PLUGINS_SRC is not a porto-api-plugins tree." >&2
  exit 1
fi

echo "Packaging hexagonalboot-api host..."
(cd "$PORTO_API_SRC" && ./mvnw -q -DskipTests package)
BOOT_JAR="$(ls -1t "$PORTO_API_SRC"/target/*.jar 2>/dev/null | grep -vi original | grep -Ev '(sources|javadoc)\.jar$' | head -1)"
if [ -z "${BOOT_JAR:-}" ]; then
  echo "No boot jar in $PORTO_API_SRC/target after package." >&2
  exit 1
fi
cp "$BOOT_JAR" "$ROOT/porto-api.jar"
echo "Copied $BOOT_JAR -> $ROOT/porto-api.jar"

echo "Packaging plugins into $ROOT ..."
(cd "$PORTO_API_PLUGINS_SRC" && mvn -q -DskipTests package -Dporto.api.home="$ROOT")

cd "$ROOT"
exec docker compose up --build "$@"
