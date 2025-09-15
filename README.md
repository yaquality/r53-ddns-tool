# Route53 DDNS Tools

AWS Route53を使用したDynamic DNSツールです。定期的にグローバルIPアドレスをチェックし、変更があった場合にRoute53のAレコードを自動更新します。

## 機能

- グローバルIPアドレスの自動取得
- Route53 Aレコードの自動更新（IPアドレス変更時のみ）
- systemdタイマーによる定期実行（設定可能）

## 前提条件

- Route53ホストゾーンへのアクセス権限
- Linux環境（systemd対応）
- sudo権限（Pythonビルド依存関係のインストール用）

## セットアップ

### 初回導入
```bash
./setup_environment.sh
```

このスクリプトは以下を自動で実行します：
- Pythonビルドに必要なシステムパッケージのインストール
- pyenvのインストールとシェル設定
- Python 3.12.8のインストール
- Python仮想環境の作成
- AWS CLIのインストール
- 設定ファイルの作成

### 設定

1. AWS設定：

   **a) IAMユーザーの作成（AWSコンソール）:**
   - AWSコンソールにIAMサービスでアクセス
   - 「ユーザー」→「ユーザーを作成」
   - ユーザー名を入力（例: `ddns-user`）
   - 「アクセスキーを提供する」にチェック

   **b) IAMポリシーの作成とアタッチ:**
   - 「ポリシー」→「ポリシーの作成」
   - ポリシー名: `Route53DDNSPolicy`
   - 以下のJSONを貼り付け（`YOUR_ZONE_ID`を実際のゾーンIDに置換）:
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "route53:ListResourceRecordSets",
                   "route53:ChangeResourceRecordSets"
               ],
               "Resource": "arn:aws:route53:::hostedzone/YOUR_ZONE_ID"
           }
       ]
   }
   ```
   - 作成したユーザーにポリシーをアタッチ
   - アクセスキーとシークレットアクセスキーをメモ

   **c) AWS CLIの設定:**
   ```bash
   aws configure
   ```
   - AWS Access Key ID: 上記で作成したアクセスキー
   - AWS Secret Access Key: 上記で作成したシークレットアクセスキー
   - Default region name: ホストゾーンのリージョン（例: `us-east-1`）
   - Default output format: `json`

2. Route53ゾーンIDの確認：
   ```bash
   aws route53 list-hosted-zones
   ```
   ドメイン名から対応する`Id`を確認（`/hostedzone/`以降の部分）

3. 設定ファイルを編集：
   ```bash
   vim config.sh
   ```
   - `ZONE_ID`: Route53のゾーンID（上記で確認した値）
   - `RECORD_NAME`: 更新するレコード名（例: `home.example.com.`）
   - `PROJECT_PATH`: プロジェクトの絶対パス（自動設定済み）
   - `EXECUTION_INTERVAL`: 実行間隔（例: 5min, 10min, 1h）

4. systemdサービスの有効化：
   ```bash
   ./setup_systemd.sh
   ```

## 使用方法

### 手動実行
```bash
./update_ddns.sh
```

### サービス状態確認
```bash
sudo systemctl status update-ddns.timer
sudo systemctl status update-ddns.service
```

### ログ確認
```bash
journalctl -u update-ddns.service -f
```

## ファイル構成

- `update_ddns.sh`: メインスクリプト
- `setup_environment.sh`: 初回環境構築スクリプト
- `setup_systemd.sh`: systemdセットアップスクリプト
- `config.sh.sample`: 設定ファイルのサンプル
- `config.sh`: 環境固有の設定ファイル（Git管理対象外）
- `etc/systemd/system/update-ddns.service`: systemdサービス設定テンプレート
- `etc/systemd/system/update-ddns.timer`: systemdタイマー設定テンプレート