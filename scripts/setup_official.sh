#!/bin/bash
# 比較に使う論文の公式実装を official/ に取得し、動かすための環境を作る。
# 公式実装は検証に使ったコミットに合わせる。済んでいる段は飛ばすので、何度実行してもよい。
# 使い方: scripts/setup_official.sh   (どのディレクトリから実行してもよい)
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p official

# 指定のコミットだけを取得する (履歴は取らない。py-tetrad は履歴だけで 1GB を超える)
fetch_at() {  # <URL> <ディレクトリ名> <コミット>
  local url=$1 dir=official/$2 commit=$3
  if [ -d "$dir/.git" ]; then
    echo "skip: $dir (取得済み)"
    return
  fi
  git init --quiet "$dir"
  git -C "$dir" remote add origin "$url"
  git -C "$dir" fetch --quiet --depth 1 origin "$commit"
  git -C "$dir" checkout --quiet FETCH_HEAD
  echo "ok: $dir @ ${commit:0:7}"
}

# 1. 公式実装 (中身には手を入れない)
fetch_at https://github.com/TURuibo/MVPC         MVPC      e95160c00987f540e47af776bbd7b6a1d9c25d5b
fetch_at https://github.com/ErdunGAO/MissDAG     MissDAG   3c1eeed8f6245670614d2f2938ee3c3b5a21f17b
fetch_at https://github.com/muralikgs/missnodag  missnodag bc1bf6b34cbffd2155a2592508fbc81f42abe468
fetch_at https://github.com/cmu-phil/py-tetrad   py-tetrad 25ac2f31b96a92cf969cfea168123e143110a1f6

# 2. MissNODAG は依存の版が固定されているので、本体とは別の環境 (official/missnodag/.venv) で動かす
if [ -x official/missnodag/.venv/bin/python ]; then
  echo "skip: official/missnodag/.venv (作成済み)"
else
  (cd official/missnodag && uv sync)
fi

# 3. MVPC (R) が使う R パッケージを official/Rlib に入れる (R 4.4 で確認)
if [ -d official/Rlib/pcalg ]; then
  echo "skip: official/Rlib (導入済み)"
else
  mkdir -p official/Rlib
  (cd official && Rscript install_r.R)
fi

# 4. Tetrad の jar は Java 21 以上を要するので、Temurin 21 の JDK を official/jdk に展開する
if ls -d official/jdk/jdk-21* > /dev/null 2>&1; then
  echo "skip: official/jdk (展開済み)"
else
  case "$(uname -s)" in
    Darwin) os=mac ;;
    Linux) os=linux ;;
    *) echo "この OS では JDK を自動で入れられない。Temurin 21 を official/jdk/ に展開する" >&2; exit 1 ;;
  esac
  case "$(uname -m)" in
    arm64 | aarch64) arch=aarch64 ;;
    x86_64) arch=x64 ;;
    *) echo "この CPU では JDK を自動で入れられない。Temurin 21 を official/jdk/ に展開する" >&2; exit 1 ;;
  esac
  mkdir -p official/jdk
  curl -fsSL "https://api.adoptium.net/v3/binary/latest/21/ga/${os}/${arch}/jdk/hotspot/normal/eclipse" |
    tar -xz -C official/jdk
  echo "ok: official/jdk"
fi

echo "done"
