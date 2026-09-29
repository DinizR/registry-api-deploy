#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORTO_API_SRC="${PORTO_API_SRC:-$HOME/projects/porto-api}"
PORTO_API_PLUGINS_SRC="${PORTO_API_PLUGINS_SRC:-$HOME/projects/porto-api-plugins}"

if [ ! -f "$PORTO_API_SRC/pom.xml" ]; then
  echo "PORTO_API_SRC=$PORTO_API_SRC is not a porto-api tree." >&2
  exit 1
fi
if [ ! -f "$PORTO_API_PLUGINS_SRC/pom.xml" ]; then
  echo "PORTO_API_PLUGINS_SRC=$PORTO_API_PLUGINS_SRC is not a porto-api-plugins tree." >&2
  exit 1
fi

echo "Packaging porto-api host..."
(cd "$PORTO_API_SRC" && ./mvnw -q -DskipTests package)
BOOT_JAR="$(ls -1t "$PORTO_API_SRC"/target/porto-api-*.jar | grep -v 'original' | head -1)"
cp "$BOOT_JAR" "$ROOT/porto-api.jar"
echo "Copied $BOOT_JAR -> $ROOT/porto-api.jar"

echo "Packaging plugins into $ROOT ..."
(cd "$PORTO_API_PLUGINS_SRC" && mvn -q -DskipTests package -Dporto.api.home="$ROOT")

cd "$ROOT"
exec docker compose up --build "$@"
