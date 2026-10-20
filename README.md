# 迷ったら、偶然の一節に問う｜辻

迷ったとき、無作為に開いた聖書の一節を手がかりに「迷いからの出口」を得るアプリ。
ナシーム・ニコラス・タレブ『反脆弱性』で紹介された書物占いを現代に落とし込む試み。占いではなく「考えるための道具」。

詳細な設計・TODO は [specification.md](specification.md) を参照。

## 必要な環境
### 使う人
- Web 版: ブラウザだけ（iPhone の Safari など）。インストール不要。記録はそのブラウザの中だけに残る

### 開発する人
- Mac（Mac 試作版は Command Line Tools だけで動く。iPhone 版は Xcode が必要）
- iPhone 実機での確認や App Store 公開をする場合は、Apple ID / Apple Developer Program

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

## Web 版の起動（この Mac で確認）
Finder で `Web版を起動.command` をダブルクリックする（ブラウザで開く。試用モード: 待ち時間10秒）。
初回は聖書データと字体の準備に数十秒かかる。止めるときはターミナルで Ctrl+C。

```sh
./tools/run_web.sh                 # 通常（1日1回）
COOLDOWN=10 ./tools/run_web.sh     # 10秒で書をひらき直せる
```

公開の仕組みは specification.md の 4.3 を参照。

## 聖書データ
eBible.org のパブリックドメイン訳を使用（日本語: フリーダム・バイブル、英語: World English Bible）。
作り直す場合は `tools/build_bible.py` を参照。

## iPhone 版の起動（シミュレーター）
1. Finder で `iPhone版を起動.command` をダブルクリックする（Xcode でプロジェクトが開く）
2. Xcode 上部の端末選択で iPhone のシミュレーターを選び、▶（Run）を押す

ターミナルから画面なしでビルド・起動だけ確認する場合は `./tools/run_ios.sh`。
