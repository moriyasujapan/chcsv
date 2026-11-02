#!/bin/bash
# OL8/OL9 × Instant Client 19/21/26ai の 6 組合せでビルド行列を回す。
# リポジトリ ROOT から実行:  ./docker/matrix-test.sh
# 結果は matrix-logs/results.txt に PASS/FAIL 行として追記される。
#
# 環境変数:
#   DOCKER_NETWORK=host   bridge DNS が壊れた環境（systemd-resolved 等）では host を指定
#   BUILD_HOME=...        buildx が ~/.docker に書けない環境では書き込み可能な dir を指定
cd "$(dirname "$0")/.." || exit 1
mkdir -p matrix-logs
: > matrix-logs/results.txt
NET_OPT=""
[ -n "$DOCKER_NETWORK" ] && NET_OPT="--network=$DOCKER_NETWORK"
for os in "ol8 oraclelinux:8" "ol9 oraclelinux:9"; do
  set -- $os; OS=$1; BASE=$2
  for v in "19 1933000 19.33.0.0.0dbru" "21 2124000 21.24.0.0.0dbru" "26ai 2326400 23.26.4.0.0"; do
    set -- $v; TAG=$1; DIR=$2; VER=$3
    LOG=matrix-logs/${OS}-ic${TAG}.log
    if HOME="${BUILD_HOME:-$HOME}" docker build $NET_OPT -f docker/Dockerfile \
        --build-arg BASE="$BASE" --build-arg IC_DIR="$DIR" --build-arg IC_VER="$VER" \
        -t "chcsv-matrix:${OS}-ic${TAG}" . > "$LOG" 2>&1; then
      echo "PASS $OS ic$TAG" >> matrix-logs/results.txt
    else
      echo "FAIL $OS ic$TAG  ($(grep -E 'error|Error|failed|PCC-' "$LOG" | tail -1 | cut -c1-120))" >> matrix-logs/results.txt
    fi
  done
done
echo MATRIX_DONE >> matrix-logs/results.txt
cat matrix-logs/results.txt
