# cyclic-missing-benchmark

巡回構造と欠測が併存するデータで、因果探索の既存手法がどの条件で破綻するかを調べる検証コードです。
巡回の強さと欠測の機構・割合を別々に制御できる合成データの生成器、評価指標、既存手法のラッパ、実験をまとめています。

Verification code for existing causal discovery methods on synthetic data with feedback cycles and missing values (documentation in Japanese).

卒業研究「欠測下で巡回構造を許す制約ベース因果探索アルゴリズムの提案」のうち、既存手法の検証に使ったコードです。提案手法は含みません。

## 中身

| ファイル | 内容 |
|---|---|
| `cyclic_missing_verification.ipynb` | 検証コード一式。`%%module 名前` のセルがそれぞれ1つのモジュールになる |
| `scripts/setup_official.sh` | 比較に使う公式実装を `official/` に取得し、動かす環境を作る |
| `official/install_r.R` | MVPC（R）が使う R パッケージを `official/Rlib` に入れる（setup_official.sh から呼ぶ） |
| `pyproject.toml`、`uv.lock` | ノートブックを動かす Python 環境 |

## 生成するデータ

線形 SEM x = Bx + e から、次の構造のデータを作ります（ノートブックの 2.2 節）。

- Z → X1（Z は巡回の外の外生変数で、欠測しない）
- 未観測の交絡 L → X1、L → X2
- 巡回：非巡回なら X1 → X2、2-cycle なら X1 ⇄ X2、長さ3なら X1 → X2 → X3 → X1
- 巡回のノードすべて → Y

振れる条件は次のとおりです。

- 巡回の複雑さ：非巡回 / 2-cycle / 長さ3
- フィードバックの強さ：B のスペクトル半径 ρ（0.1〜0.9）
- 欠測の機構：MCAR / MAR / 自己マスキング / 自己と別の観測変数の両方に依存する型
- 欠測率と位置：5〜60%、巡回の中か外か
- 誤差の分布：ガウス / 一様 / ラプラス / ガンベル

## 比べる手法

| 手法 | 実装 |
|---|---|
| PC（行ごと削除・平均代入）、MVPC、FCI | causal-learn 0.1.4.8 |
| DirectLiNGAM、ICA-LiNGAM、RCD、m-LiNGAM | lingam 1.12.2 |
| LiNG-D | ノートブック内の実装と Tetrad |
| CCD、FCI | Tetrad 7.6.11（py-tetrad 同梱の jar を JPype で呼ぶ） |
| MVPC | 著者の R 実装 |
| MissDAG | 著者の実装（線形ガウス版） |
| MissNODAG | 著者の実装（専用の Python 環境で動かす） |
| 相関の閾値、完全グラフ | 自明なベースライン |

causal-learn の MVPC には、欠測指標の親の検出を直した版（mvpc_fixed）も用意しています。

## 必要なもの

- Python 3.13 と [uv](https://docs.astral.sh/uv/)
- git と curl（公式実装と JDK の取得に使う）
- R 4.4（MVPC の著者実装を動かすとき）
- Java 21（Tetrad が使う。setup_official.sh が Temurin 21 を `official/jdk` に入れる）

macOS（Apple Silicon）で動作を確かめています。

## セットアップ

```sh
uv sync
scripts/setup_official.sh
```

setup_official.sh は次のことをします。済んでいる段は飛ばします。

1. 公式実装4つを `official/` に取得し、検証に使ったコミットに合わせる（履歴は取らない）
2. `official/missnodag` で `uv sync` する（MissNODAG は依存の版が固定されているので、本体とは別の環境で動かす）
3. `official/install_r.R` で R パッケージを `official/Rlib` に入れる
4. Temurin 21 の JDK を `official/jdk` に展開する

| 公式実装 | コミット | 論文 |
|---|---|---|
| [TURuibo/MVPC](https://github.com/TURuibo/MVPC) | e95160c | Tu ら, AISTATS 2019 |
| [ErdunGAO/MissDAG](https://github.com/ErdunGAO/MissDAG) | 3c1eeed | Gao ら, NeurIPS 2022 |
| [muralikgs/missnodag](https://github.com/muralikgs/missnodag) | bc1bf6b | Sethuraman ら, TMLR 2026 |
| [cmu-phil/py-tetrad](https://github.com/cmu-phil/py-tetrad) | 25ac2f3（Tetrad 7.6.11） | Ramsey と Andrews, 2023 |

公式実装の中身には手を入れておらず、このリポジトリにも含めていません。それぞれのライセンスに従ってください。

## 使い方

```sh
uv run jupyter lab cyclic_missing_verification.ipynb
```

リポジトリの直下で開き、上から順に実行します。

- `QUICK = True`（既定）：反復数と標本数を小さくして一通り動かします（手元の環境で約6分）。結果は `outputs_quick/` と `figures_quick/` に書きます。
- `QUICK = False`：検証と同じ設定で回します。全体で数十時間かかり、公式実装を加えた4軸の実験だけで約26時間です。結果は `outputs/` と `figures/` に書きます。
- `RUN` の項目を `False` にすると、その実験を飛ばします。
- 3.10 節が、使ったパッケージの版と公式実装のコミットを `environment.json` に書き出します。

## ノートブックの構成

1. 準備
2. 共通部品：評価指標、生成器、d分離、既存手法のラッパ、公式実装のラッパ、生成器の診断、4軸の実験ランナー
3. 9月の検証：生成器の診断と 2-cycle の識別可能性、d分離での確認、欠測が条件付き独立を壊す条件、欠測による従属の減衰、巡回の判別に効く検定、欠測が巡回の判別を壊す条件、有限標本での偽の巡回、評価4軸での既存手法の比較、図の作成、版の記録
4. 10月の検証：公式実装との突き合わせ、CCD の神託出力、骨格の正解の置き方、公式実装での偽の巡回、MVPC の食い違いの切り分け（乱数の揺れ、親の検出の誤り、補正の段の差）、偽の巡回の割合の非単調性、公式実装を加えた4軸の実験、causal-learn の手法の再実行、MissNODAG

## 参考文献

- P. Spirtes, C. Meek, and T. Richardson, "An Algorithm for Causal Inference in the Presence of Latent Variables and Selection Bias," in *Computation, Causation, and Discovery*, AAAI Press, pp. 211–252, 1999.
- T. Richardson, "A Discovery Algorithm for Directed Cyclic Graphs," *UAI*, pp. 454–461, 1996.
- G. Lacerda, P. Spirtes, J. Ramsey, and P. O. Hoyer, "Discovering Cyclic Causal Models by Independent Components Analysis," *UAI*, pp. 366–374, 2008.
- R. Tu, C. Zhang, P. Ackermann, K. Mohan, H. Kjellström, and K. Zhang, "Causal Discovery in the Presence of Missing Data," *AISTATS*, PMLR 89, pp. 1762–1770, 2019.
- E. Gao, I. Ng, M. Gong, L. Shen, W. Huang, T. Liu, K. Zhang, and H. Bondell, "MissDAG: Causal Discovery in the Presence of Missing Data with Continuous Additive Noise Models," *NeurIPS*, 2022.
- M. G. Sethuraman, R. Nabi, and F. Fekri, "MissNODAG: Differentiable Learning of Cyclic Causal Graphs from Incomplete Data," *TMLR*, 2026.
- Y. Zheng, B. Huang, W. Chen, J. Ramsey, M. Gong, R. Cai, S. Shimizu, P. Spirtes, and K. Zhang, "Causal-learn: Causal Discovery in Python," *JMLR*, 25(60), pp. 1–8, 2024.
- J. Ramsey and B. Andrews, "Py-Tetrad and RPy-Tetrad: A New Python Interface with R Support for Tetrad Causal Search," *Causal Analysis Workshop Series*, PMLR 223, pp. 40–51, 2023.
- lingam: <https://github.com/cdt15/lingam>
