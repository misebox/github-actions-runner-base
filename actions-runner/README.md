# Github Actions Self-hosted Runner

自分のマシンをgithub actionsのrunner として使う方法を簡単におしえてくれる？

### ChatGPT said:

GitHub Actionsで自分のマシン（自前のPCやサーバー）をランナーとして使う方法は以下の通り。最短ステップだけ示します。

---

### ✅ 前提

- GitHubリポジトリがある（例: `yourname/yourrepo`）
- 自分のマシンで常時または一時的にランナーを動かしたい

---

### 🛠️ 手順（Linux/macOS用。Windowsでも類似）

1. **GitHubでランナー登録ページを開く**
    
    [https://github.com/`yourname`/`yourrepo`/settings/actions/runners](https://github.com/%60yourname%60/%60yourrepo%60/settings/actions/runners)
    
2. **「New self-hosted runner」→ OSを選択**
3. **表示されるコマンドを実行（例：Linux）**

```bash
bash
CopyEdit
mkdir actions-runner && cd actions-runner
curl -O -L https://github.com/actions/runner/releases/download/v2.X.X/actions-runner-linux-x64-2.X.X.tar.gz
tar xzf actions-runner-linux-x64-2.X.X.tar.gz
./config.sh --url https://github.com/yourname/yourrepo --token YOUR_TOKEN_HERE

```

1. **ランナーを起動**

```bash
bash
CopyEdit
./run.sh

```

---

### 🌀 永続化したい場合

systemd や launchd でサービス化すると良い。GitHubの表示にも「as a service」での方法が記載されてる。

---

### 🔄 削除・再登録したいとき

```bash
bash
CopyEdit
./config.sh remove

```

---

これで、`.github/workflows/*.yml` の `runs-on` に `self-hosted` を指定すればOK。

```yaml
yaml
CopyEdit
jobs:
  myjob:
    runs-on: self-hosted
    steps:
      - run: echo "Running on my own machine"

```

必要があればタグも指定可能（`--labels`）。

### You said:

そんなに簡単なんかい。現在ランナーとして稼働中かどうかをダッシュボード的にいつでも確認できるようにしたいんだけど良い方法は？

### ChatGPT said:

以下のいずれかで、**自分のGitHub Actionsランナーが稼働中かどうか**を手元でダッシュボード的に確認できます：

---

### ✅ 方法1：GitHubのWeb UIで確認（標準）

- URL: `https://github.com/<owner>/<repo>/settings/actions/runners`
- ステータス：「Idle」「Active」「Offline」など表示される
    
    → *最も確実だけど手動で見に行く必要あり*
    

---

### ✅ 方法2：GitHub CLI + スクリプトで定期監視（おすすめ）

```bash
bash
CopyEdit
gh api \
  repos/<owner>/<repo>/actions/runners \
  --jq '.runners[] | {name, status, busy}'

```

例：

```bash
bash
CopyEdit
gh api repos/yourname/yourrepo/actions/runners --jq '.runners[] | "\(.name): \(.status) \(.busy)"'

```

- `status` → `"online"` or `"offline"`
- `busy` → `true` なら実行中

→ この出力を `watch` コマンドなどで定期表示すれば、ダッシュボードっぽくなる。

```bash
bash
CopyEdit
watch -n 5 'gh api repos/yourname/yourrepo/actions/runners --jq ".runners[] | \"\(.name): \(.status) \(.busy)\""'

```

---

### ✅ 方法3：自作Webダッシュボード

Node.jsやPython Flaskなどで `gh api` 経由 or GitHub REST API直接叩いて状態を取得 → Web UIで表示

（ただしトークン管理とRateLimit注意）

---

### ✅ 方法4：自マシン側でsystemd＋ログ監視

- ランナーをsystemdで登録し、`systemctl is-active actions.runner...` などで状態確認
- ローカルで `ps -ef | grep run.sh` 監視でもOK

---

### まとめ

| 方法 | 特徴 |
| --- | --- |
| GitHub UI | 正確・公式・だが手動 |
| `gh api` + `watch` | 軽量・ローカルで即確認可 |
| 自作Web UI | 本格的監視に最適（手間は増） |
| systemd監視 | ローカルプロセス確認用途向け |

軽くやるなら **`gh api` + `watch`** が最速で便利だよ。

### You said:

登録しようとすると、エラーになるよ。
Enter the name of the runner group to add this runner to: [press Enter for Default] m153-a520i-ac

Could not find any self-hosted runner group named "m153-a520i-ac".
An error occurred: Not configured. Run config.(sh/cmd) to configure the runner.
Runner listener exit with terminated error, stop the service, no retry needed.
Exiting runner...

2/2

### ChatGPT said:

このエラーは、**runner group の名前に「自分のマシン名」を入力してしまった**ために発生しています。

---

### ❌ 現状の誤解：

```
vbnet
CopyEdit
Enter the name of the runner group to add this runner to: [press Enter for Default]
m153-a520i-ac

```

ここは「**グループ名（Defaultなど）**」を指定する場所で、**マシン名を入力する場所ではありません**。

---

### ✅ 正しい対応：

**そのまま Enter を押して「Default」グループにする**だけでOK：

```
vbnet
CopyEdit
Enter the name of the runner group to add this runner to: [press Enter for Default]
(ここで Enter を押す)

```

これで通るはず。

---

### 🔁 もう一度やり直すには：

```bash
bash
CopyEdit
./config.sh remove
./config.sh --url https://github.com/yourname/yourrepo --token YOUR_TOKEN

```

→ 「runner group」の質問で **何も入力せずに Enter**。

---

### 補足：

- **Runner name** はあとで別の質問として出ます（ここではマシン名を入れてOK）。
- **Runner group** は GitHub Enterprise でなければ「Default」のみが使えるので、空で良い。

### You said:

runner の起動と終了は？

### ChatGPT said:

GitHub Actions Runner の起動と終了は以下の通りです。

---

## ✅ 一時的に手動起動・終了したい場合

```bash
bash
CopyEdit
cd actions-runner
./run.sh   # 起動（前面で動作）

```

- `Ctrl + C` で終了
- 実行中のターミナルが閉じられると runner も止まる

---

## ✅ 常駐サービスとして起動・終了したい場合（推奨）

`config.sh` 実行後に以下のコマンドが出る：

```bash
bash
CopyEdit
sudo ./svc.sh install
sudo ./svc.sh start

```

これにより systemd サービスとして登録され、バックグラウンドで常時動作します。

### その他の操作：

| 操作 | コマンド |
| --- | --- |
| 起動 | `sudo ./svc.sh start` |
| 停止 | `sudo ./svc.sh stop` |
| ステータス | `sudo ./svc.sh status` |
| 自動起動設定 | `sudo systemctl enable actions.runner...` |

※ `actions.runner.yourname-yourrepo.<runnername>.service` の形式になる

---

## ✅ アンインストール

```bash
bash
CopyEdit
sudo ./svc.sh stop
sudo ./svc.sh uninstall
./config.sh remove

```

---

## 🔄 再起動

```bash
bash
CopyEdit
sudo ./svc.sh restart

```

---

バックグラウンド運用したいなら **`svc.sh install/start` の使用がベスト**です。
