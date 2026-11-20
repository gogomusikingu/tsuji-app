# CLAUDE.md — 辻（Random）

共通の決まり（`~/project/CLAUDE.md`）に足す、辻だけの決まりと案内。説明書の入口は `specification.md`。

## 概要

- 迷った時に無作為に開いた聖書の一節を手がかりに「迷いからの出口」を得る、考えるための道具（占いではない）。Mac 試作版・iPhone 版（Swift / SwiftUI）・Web 版（静的サイト）の 3 つ
- コードは `Sources/RandomOracle/`（Mac・iPhone）、`web/`（Web 版）、`ios/`、`tools/`。聖書本文は同梱（サーバーなし・外部 API なし）
- GitHub の `origin` は**公開**の `gogomusikingu/tsuji-app`（Web 版を GitHub Pages に公開）。**`main` への push で Web 版が公開される**ので、`main` への取り込みは節目にユーザーの了承を得てから。`archive`（`tsuji`）は非公開の保管。作業は `dev`
- 公開リポジトリなので、個人の情報・秘密・ユーザーの発言の引用をこのリポジトリの .md に書かない

## 確かめ方

- Web 版: `node --test web/tests/*.test.js`（10 本）
- Mac・iPhone 版: `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk swift test --scratch-path .build/sdk26`（13 本・約 20 秒）。テストファイルを変えた直後の 1 回目は「TestingMacros が見つからない」と失敗することがあり、もう一度流すと通る
- 文書を変えたら `python3 tools/check_docs.py`。保存の時は文書のチェックと、コードを含む時は上の 2 つのテストが自動で走る（有効にするのは `git config core.hooksPath tools/githooks`）

## 今効いている決まり

- 乱数は偏りのない暗号用の乱数。記録は端末（Web 版はブラウザの localStorage）の中だけ。秘密の鍵・外部 API は持たない（公開しても守るものがない構成にする）
- 聖書は eBible.org のパブリックドメイン訳（日本語: フリーダム・バイブル、英語: World English Bible）。作り直しは `tools/build_bible.py`
- Command Line Tools の macOS 27 SDK は SwiftUI のマクロが使えない。ビルドは macOS 26 SDK を指定する（`tools/run_mac.sh`）
- 画面文字は `Language.swift` の表で管理（日本語・英語）
- 起動のショートカット（`試作版を起動.command`・`Web版を起動.command`・`iPhone版を起動.command`）と使い方は `README.md`

## 読む物の案内

全部は読まない。作業に当たる行のファイルだけを、作業の前に読む。章番号の行き先は `spec/章番号.md`。

- 最初に: `TODO.md`
- コンセプト・対象・機能（3 章: 書をひらく・書き込み・シェア・体験の方針）、本文データと著作権、運用方針、未決事項 → `specification.md`
- ビルド、Mac・iPhone・Web 版の作り、公開の仕組み、ディレクトリ構成（4 章） → `spec/技術方針.md`
- アプリ名・デザイン・売り出し方（7 章） → `spec/売り出し方.md`
- 変更履歴、整理前の説明書、済みの TODO → `spec/履歴/`（普段は読まない。変更履歴の先頭に 1〜2 行足す）
