#!/bin/bash
set -euo pipefail

export PORTO_API_HOME="$(cd "$(dirname "$0")/.." && pwd)"
export API_ENV="${API_ENV:-dev}"
export LOG_PATH="${LOG_PATH:-$PORTO_API_HOME/logs}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"
mkdir -p "$LOG_PATH"

PORTO_API_SRC="${PORTO_API_SRC:-$(cd "$PORTO_API_HOME/../hexagonalboot-api" && pwd)}"
JAR=""
if ls "$PORTO_API_HOME"/porto-api-*.jar >/dev/null 2>&1; then
  JAR="$(ls -1t "$PORTO_API_HOME"/porto-api-*.jar | head -1)"
fi

echo "PORTO_API_HOME=$PORTO_API_HOME"
echo "API_ENV=$API_ENV"
echo "LOG_PATH=$LOG_PATH"

if [ -n "$JAR" ]; then
  exec java -jar "$JAR"
fi

if [ ! -f "$PORTO_API_SRC/pom.xml" ]; then
  echo "No porto-api jar in $PORTO_API_HOME and PORTO_API_SRC=$PORTO_API_SRC is not a hexagonalboot-api tree." >&2
  echo "Set PORTO_API_SRC or copy the boot jar into this directory." >&2
  exit 1
fi

cd "$PORTO_API_SRC"
exec ./mvnw spring-boot:run
