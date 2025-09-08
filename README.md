# Route53 DDNS Tools

AWS Route53を使用したDynamic DNSツールです。定期的にグローバルIPアドレスをチェックし、変更があった場合にRoute53のAレコードを自動更新します。

## 機能

- グローバルIPアドレスの自動取得
- Route53 Aレコードの自動更新（IPアドレス変更時のみ）
- systemdタイマーによる定期実行（設定可能）

## 前提条件

- AWS CLI設定済み
- Route53ホストゾーンへのアクセス権限
- pyenv環境
- Python仮想環境（.venv）

## セットアップ

1. 設定ファイルを作成：
   ```bash
   cp config.sh.sample config.sh
   vim config.sh
   ```
   - `ZONE_ID`: Route53のゾーンID
   - `RECORD_NAME`: 更新するレコード名
   - `PROJECT_PATH`: プロジェクトの絶対パス
   - `EXECUTION_INTERVAL`: 実行間隔（例: 5min, 10min, 1h）

2. systemdサービスの有効化：
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
- `setup_systemd.sh`: systemdセットアップスクリプト
- `config.sh.sample`: 設定ファイルのサンプル
- `config.sh`: 環境固有の設定ファイル（Git管理対象外）
- `etc/systemd/system/update-ddns.service`: systemdサービス設定テンプレート
- `etc/systemd/system/update-ddns.timer`: systemdタイマー設定テンプレート