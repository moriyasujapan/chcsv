# chcsv (Pro*C, 1995) を Instant Client + Pro*C プリコンパイラだけでビルドする
# ベース OS: oraclelinux:8 / oraclelinux:9（glibc 2.28 / 2.34 以上なら他ディストリでも可）
#
#   docker build -f docker/Dockerfile \
#     --build-arg BASE=oraclelinux:9 \
#     --build-arg IC_DIR=2124000 --build-arg IC_VER=21.24.0.0.0dbru \
#     -t chcsv:ol9-ic21 .
#
# IC_DIR / IC_VER の対応は docs/BUILD-DOCKER.md の表を参照。
ARG BASE=oraclelinux:8
FROM ${BASE}

ARG IC_DIR=2124000
ARG IC_VER=21.24.0.0.0dbru

RUN dnf -y install gcc make unzip libaio libnsl curl && dnf clean all

# Instant Client: ランタイム(basic-lite) + SDK(ヘッダ) + Pro*C プリコンパイラ(proc)。
# 3 つとも認証不要でダウンロードできる。解凍先ディレクトリ名は版によって
# instantclient_21_24 / instantclient_19_33 のように異なるため find で寄せる。
RUN mkdir -p /opt/ic /tmp/z && cd /tmp/z \
 && base="https://download.oracle.com/otn_software/linux/instantclient/${IC_DIR}" \
 && for k in basiclite sdk precomp; do \
      curl -fsSLO "${base}/instantclient-${k}-linux.x64-${IC_VER}.zip" || \
      curl -fsSLO "${base}/instantclient-${k}-linux.x64-${IC_VER}.zip"; \
    done \
 && for f in *.zip; do unzip -oq "$f" -d /opt/ic; done \
 && rt=$(dirname "$(find /opt/ic \( -type f -o -type l \) -name 'libclntsh.so*' | head -1)") \
 && ln -s "$rt" /opt/ic/rt \
 && rm -rf /tmp/z

COPY . /src
COPY docker/build.sh /build.sh
RUN /build.sh \
 && (LD_LIBRARY_PATH=/opt/ic/rt /out/chcsv 2>&1 | grep -q 'Batayan') \
 && echo "BUILD+SMOKE OK"
