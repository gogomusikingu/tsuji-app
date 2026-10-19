# 迷ったら、偶然の一節に聞く｜辻

迷ったとき、無作為に開いた聖書の一節を手がかりに「迷いからの出口」を得る iPhone アプリ。
タレブ『反脆弱性』で紹介された書物占いを現代に落とし込む試み。占いではなく「考えるための道具」。

詳細な設計・TODO は [specification.md](specification.md) を参照。

## 必要な環境
- Mac（試作版は Command Line Tools だけで動く。iPhone 版は Xcode が必要）
- iPhone（動作確認用）
- Apple Developer Program（App Store 公開時）

## Mac 試作版の起動
Finder で `試作版を起動.command` をダブルクリックする（試用モード: 待ち時間10秒）。
またはターミナルで次を実行する（初回はビルドに1分ほどかかる）。

```sh
cd ~/project/Random
./tools/run_mac.sh
```

試しに何度も引きたいときは、待ち時間を秒で指定できる（例: 10秒）。

```sh
RANDOM_ORACLE_COOLDOWN=10 ./tools/run_mac.sh
```

## 聖書データ
eBible.org のパブリックドメイン訳を使用（日本語: フリーダム・バイブル、英語: World English Bible）。
作り直す場合は `tools/build_bible.py` を参照。

## iPhone 版の起動（シミュレーター）
1. Finder で `iPhone版を起動.command` をダブルクリックする（Xcode でプロジェクトが開く）
2. Xcode 上部の端末選択で iPhone のシミュレーターを選び、▶（Run）を押す

ターミナルから画面なしでビルド・起動だけ確認する場合は `./tools/run_ios.sh`。
