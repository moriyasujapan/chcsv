#!/bin/bash
# chcsv を Instant Client の Pro*C でビルドする（バージョン非依存）。
# 前提: /opt/ic/rt に basic-lite+sdk+precomp を解凍済み（Dockerfile 参照）。
# 手順の根拠（はまった点）は docs/BUILD-DOCKER.md に記載。
set -euo pipefail

RT=/opt/ic/rt
PROC=$(find /opt/ic -type f -name proc | head -1)
[ -n "$PROC" ] || { echo "proc not found under /opt/ic"; exit 1; }
export LD_LIBRARY_PATH=$RT

# --- 1) pcscfg.cfg: proc は LD_LIBRARY_PATH から逆算した precomp/admin/pcscfg.cfg を要求する
mkdir -p "$RT/precomp/admin"
printf 'sys_include=/root/psafe\n' > "$RT/precomp/admin/pcscfg.cfg"

# --- 2) proc 用スタブヘッダ: 現行 proc は現代的 glibc ヘッダを解釈できない
#        （size_t 等で PCC-S-02201）。proc 通过りのみ空スタブに差し替える。
#        gcc は実ヘッダを見るので実行影響はない。
mkdir -p /root/psafe
for h in stdlib.h string.h strings.h errno.h fcntl.h unistd.h time.h signal.h \
         stdarg.h stddef.h setjmp.h locale.h ctype.h; do : > /root/psafe/$h; done
cat > /root/psafe/stdio.h <<'EOF'
typedef struct _pFILE FILE;
extern FILE *stdin, *stdout, *stderr;
extern int printf(), fprintf(), sprintf(), fputs(), fputc(), fclose(), fscanf();
extern FILE *fopen(), *freopen();
extern int remove(), rename();
EOF
# sqlca.h/sqlda.h は実物（proc が SQLDA/SQLCA を知っている必要がある）
for inc in $(find /opt/ic -type d -path '*sdk*include'); do
  [ -f "$inc/sqlca.h" ] && cp "$inc/sqlca.h" "$inc/sqlda.h" /root/psafe/ && break
done
[ -f /root/psafe/sqlca.h ] || { echo "sqlca.h not found in any sdk/include"; exit 1; }

# --- 3) ソース作業コピー
mkdir -p /work/src && cp /src/*.pc /src/*.h /work/src/
# proc は EXEC SQL の host variable に DECLARE SECTION 内宣言を要求する（現行版）。
# 1995 年コードはグローバル変数で通していたため sqlda.pc だけ 1 行補う。
awk '/EXEC SQL BEGIN DECLARE SECTION/{print; print "    extern int  FETCH_ARRAY;"; next} {print}' \
    /work/src/sqlda.pc > /work/src/sqlda.pc.tmp && mv /work/src/sqlda.pc.tmp /work/src/sqlda.pc

cd /work/src
# --- 4) プリコンパイル（parse は FULL 一筋。PARTIAL は EXEC SQL INCLUDE を翻訳せず、
#        #include 置換だと chcsv.h 内の EXEC SQL TYPE VARCHAR が PCC-F-02397 で弾かれる）
for f in chcsv Option OutPut Signal sqlda; do
  "$PROC" code=ANSI_C "sys_include=/root/psafe" "include=/work/src" \
      "$f.pc" oname="$f.c" > "/tmp/proc_$f.log" 2>&1 \
    || { echo "proc failed: $f"; cat "/tmp/proc_$f.log"; exit 1; }
done
# glibc 2.32+ は sys_errlist/sys_nerr をエクスポートしない（OL9 で link error）。
# 1995 年コードの宣言と使用箇所を strerror() に置き換える（全版共通、文言は同一）。
sed -i \
  -e 's/extern int errno, sys_nerr;/extern int errno;/' \
  -e 's/extern char \*sys_errlist\[\];//' \
  -e 's/errno < sys_nerr/errno < (1 << 30)/' \
  -e 's/sys_errlist\[errno\]/strerror(errno)/g' \
  chcsv.c
# sqlca の実体は 1 TU だけ必要（Instant Client の sqlca.h は宣言のみ）
printf '#include <sqlca.h>\nstruct sqlca sqlca;\n' > sqlca_inst.c

# --- 5) コンパイル/リンク
# -fcommon: gcc 10 以降の既定 -fno-common は、PROC 生成物の tentative 定義
#   (sqlca/oraca が各 TU に出現する) を multiple definition として弾く
# ヘッダは sdk を全 dir。libclntshcore は IC19 の basic-lite に .so シンボリック
#   リンクが無い場合があるため実ファイル名フォールバックを用意。
#   rpath-link は libnnz 等の推移依存に必要
INCS=""; for inc in $(find /opt/ic -type d -path '*sdk*include'); do INCS="$INCS -I$inc"; done
if [ -e "$RT/libclntshcore.so" ]; then CORE=-lclntshcore
else CORE="-l:$(cd "$RT" && ls libclntshcore.so* | head -1)"; fi
gcc -w -fcommon $INCS -I/work/src -c chcsv.c Option.c OutPut.c Signal.c sqlda.c sqlca_inst.c
gcc -o chcsv chcsv.o Option.o OutPut.o Signal.o sqlda.o sqlca_inst.o \
    -L"$RT" -lclntsh "$CORE" -Wl,-rpath-link,"$RT"
mkdir -p /out && cp chcsv /out/chcsv
echo "BUILT: $(ls -la /out/chcsv)"
