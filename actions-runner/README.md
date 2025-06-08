# GitHub Actions Self-hosted Runner

## 目次

- [概要](#概要)
- [前提](#前提)
- [セットアップ手順（Linuxmacos）](#セットアップ手順linuxmacos)
- [サービスとして常駐させる場合（推奨）](#サービスとして常駐させる場合推奨)
- [アンインストール](#アンインストール)
- [runner の状態確認](#runner-の状態確認)
- [.github/workflows/*.yml 設定例](#githubworkflowsyml-設定例)
- [よくあるエラー](#よくあるエラー)
- [補足](#補足)

## 概要

自分のマシンを GitHub Actions のランナーとして使う手順をまとめます。

---

## 前提

- GitHub リポジトリがある（例: `yourname/yourrepo`）
- ランナーを動かすマシンがある

---

## セットアップ手順（Linux/macOS）

1. **GitHub でランナー登録ページを開く**  
   `https://github.com/<owner>/<repo>/settings/actions/runners`

2. **「New self-hosted runner」→ OS を選択**

3. **表示されたコマンドを実行**  
   例:
   ```bash
   mkdir actions-runner && cd actions-runner
   curl -O -L https://github.com/actions/runner/releases/download/v2.X.X/actions-runner-linux-x64-2.X.X.tar.gz
   tar xzf actions-runner-linux-x64-2.X.X.tar.gz
   ./config.sh --url https://github.com/yourname/yourrepo --token YOUR_TOKEN
   ```
   - 「runner group」は **何も入力せず Enter**（Default でOK）
   - 「runner name」はマシン名など任意でOK

4. **ランナーを起動**
   ```bash
   ./run.sh
   ```
   - `Ctrl + C` で停止

---

## サービスとして常駐させる場合（推奨）

```bash
sudo ./svc.sh install
sudo ./svc.sh start
```

- サービス操作例:
  | 操作   | コマンド                       |
  | ------ | ----------------------------- |
  | 起動   | `sudo ./svc.sh start`         |
  | 停止   | `sudo ./svc.sh stop`          |
  | ステータス | `sudo ./svc.sh status`     |
  | 自動起動 | `sudo systemctl enable actions.runner...` |

- サービス名例: `actions.runner.yourname-yourrepo.<runnername>.service`

---

## アンインストール

```bash
sudo ./svc.sh stop
sudo ./svc.sh uninstall
./config.sh remove
```

---

## runner の状態確認

### 1. GitHub Web UI  
`https://github.com/<owner>/<repo>/settings/actions/runners`  
→ ステータス（Idle/Active/Offline）が見える

### 2. GitHub CLI  
```bash
gh api repos/<owner>/<repo>/actions/runners --jq '.runners[] | "\(.name): \(.status) \(.busy)"'
```
- `status`: `"online"` or `"offline"`
- `busy`: `true` なら実行中

定期監視例:
```bash
watch -n 5 'gh api repos/<owner>/<repo>/actions/runners --jq ".runners[] | \"\(.name): \(.status) \(.busy)\""'
```

---

## `.github/workflows/*.yml` 設定例

```yaml
jobs:
  myjob:
    runs-on: self-hosted
    steps:
      - run: echo "Running on self-hosted, Group: ${RUNNER_GROUP_NAME}, Runner: ${RUNNER_NAME}"
```

---

## よくあるエラー

- **Runner group**: 「Default」以外は GitHub Enterprise でのみ利用可。何も入力せず Enter でOK。
- **Runner name**: 任意の名前を入力。

---

## 補足

- タグ指定は `--labels` オプションで可能
- サービス運用が安定稼働にはおすすめ

---
