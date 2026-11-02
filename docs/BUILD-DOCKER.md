# Docker で原版 chcsv をビルドする（Oracle Linux 8/9 × Instant Client 19/21/26ai）

1995 年の Pro*C ソースを、有償の開発用クライアントなしで再現ビルドする方法。
Oracle Instant Client に同梱の無償 Pro*C プリプロセッサ（`proc`）を使い、
Docker の中で完結させる。

## 1 発ビルド

```console
$ docker build --network=host -f docker/Dockerfile -t chcsv .
$ docker run --rm -e LD_LIBRARY_PATH=$(docker run --rm chcsv sh -c \
    'find /opt/ic -name libclntsh.so -printf "%h\n" -quit' | sed 's/libclntsh.so//') \
    chcsv
```

既定は Oracle Linux 8 + Instant Client 21.24。変更はビルド引数で指定する:

```console
$ docker build --network=host -f docker/Dockerfile \
    --build-arg BASE=oraclelinux:9 \
    --build-arg IC_DIR=1933000 \
    --build-arg IC_VER=19.33.0.0.0dbru -t chcsv .
```

ビルド確認（usage バナーが出るか）は Dockerfile 内で自動実行している。

## 使用する ZIP（認証不要で落せる公式 URL）

| 版 | `IC_DIR` | `IC_VER` | 備考 |
|---|---|---|---|
| 19c | `1933000` | `19.33.0.0.0dbru` | basiclite/sdk/precomp 3 点とも公開 |
| 21c | `2124000` | `21.24.0.0.0dbru` | 同上 |
| 26ai | `2326400` | `23.26.4.0.0` | 23ai 系は 26ai に統合されたもの（版番 23.26.x） |

URL 形式: `https://download.oracle.com/otn_software/linux/instantclient/<IC_DIR>/instantclient-{basiclite,sdk,precomp}-linux.x64-<IC_VER>.zip`

**注: 「23ai」単体での入手は不可能。** 23ai 系の ZIP（23.4〜23.7 系、URL 表記Various）
は全て 404 を実測。Oracle 2025 のリブランドにより 23ai 行は 26ai（内部版番 23.26.x）
へ名称変更されており、`2326400` が 23ai の実体である。よって本リポジトリの
検証マトリクスでは「23」は 26ai としてカバーした。

## 検証結果（2026-02 実測）

| | IC 19.33 | IC 21.24 | IC 23.26 (26ai) |
|---|---|---|---|
| oraclelinux:8 | PASS | PASS | PASS |
| oraclelinux:9 | PASS | PASS | PASS |

6/6 組合せでビルド成功 + usage バナー確認まで通过。
`./docker/matrix-test.sh` で再現できる（結果は `matrix-logs/results.txt`）。

## はまった点（build.sh が処理している内容）

リポジトリのソースは無変更で、以下はすべて **ビルド作業コピーに対する
build.sh 側のパッチ** で吸収している。このため版別ブランチは不要だった
（全版が同一ソース・同一手順でビルドできることを 6/6 の実測で確認済み）。

1. **`pcscfg.cfg`**: `proc` はライブラリパスから逆算した
   `precomp/admin/pcscfg.cfg` を要求する。基本-lite 展開後に手で書く必要がある。
   `sys_include` に現行 glibc ヘッダを渡すと PCC-F 系エラーになるため、
   proc 专用の**空スタブヘッダ**ディレクトリを指す（gcc は実ヘッダを見るので
   コンパイル結果に影響はない。`FILE` 型だけ typedef した最小 stdio.h スタブが必要）。
2. **parse=FULL 一筋**: PARTIAL は `EXEC SQL INCLUDE` を翻訳せず、
   `#include` 置換だと `chcsv.h` 内の `EXEC SQL TYPE VARCHAR` が
   PCC-F-02397 で落ちる。FULL + `sys_include` スタブで全版通る。
3. **DECLARE SECTION**: 現行 `proc` は host variable に
   `EXEC SQL BEGIN DECLARE SECTION` 内宣言を要求する。1995 コードは
   グローバル変数で通していたため、`sqlda.pc` の宣言部に
   `extern int FETCH_ARRAY;` を 1 行補う（作業コピーのみ）。
4. **`sys_errlist`/`sys_nerr`**: glibc 2.32 でエクスポートが削除された。
   生成物の宣言と使用箇所を `strerror(errno)` に置換（文言は同一）。
5. **multiple definition**: gcc 10+ の既定 `-fno-common` は、`proc` 生成物が
   TU 横断で出す `sqlca`/`oraca` の tentative 定義を弾く。`-fcommon` で旧挙動に戻す
   （OL9 の gcc 12 で必須、OL8 の gcc 8 では無害）。
6. **`sqlca` の実体**: Instant Client の `sqlca.h` は宣言のみなので
   `struct sqlca sqlca;` を持つ 1 TU を足す。
7. **リンク**: IC19 の basic-lite には `libclntshcore.so` シンボリックリンクが
   無く `-lclntshcore` が失敗する。実ファイル名 `-l:libclntshcore.so.19.1` に
   フォールバックする。推移依存（libnnz 等）に `-Wl,-rpath-link` が必要。
   sdk ヘッダは `oratypes.h` と `sqlcpr.h` が版により別 dir に分かれるため
   全 sdk include dir を `-I` する。
8. **ZIP 展開**: 3 ZIP は同一 top-level dir を共有するため `unzip -o`（上書き）
   が必須。無指定だと確認プロンプトが EOF で非 0 終了する。

## ホスト側の注意（Docker 実行環境）

- bridge DNS が解決できない環境（`systemd-resolved` の stub を拾う等）では
  `--network=host` を付ける（上の 1 発ビルドにinclude している）。
- buildx が `~/.docker/buildx/activity` を更新できず失敗する環境では、
  `HOME` を書き込み可能な dir に向けてから実行する
  （`docker/matrix-test.sh` は `BUILD_HOME` 変数で対応）。

## 関連

- 書き込みバッファのバグ修正（`OutPut.pc` の `=` → `==`）は
  ブランチ `bugfix/buffered-write` を参照。本ビルド手順とは独立。
- Rust 再実装（同じ Instant Client/ODPI-C 構成）:
  <https://github.com/moriyasujapan/chcsv-rust>
