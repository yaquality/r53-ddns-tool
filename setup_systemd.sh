#!/bin/bash

# 設定ファイル読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# systemdファイルを一時ディレクトリにコピーして設定値を置換
TEMP_DIR=$(mktemp -d)

# サービスファイルの設定値置換
sed "s|YOUR_USERNAME|$(whoami)|g; s|/path/to/r53_ddns_tools|$PROJECT_PATH|g" \
    "$SCRIPT_DIR/etc/systemd/system/update-ddns.service" > "$TEMP_DIR/update-ddns.service"

# タイマーファイルの設定値置換
sed "s|5min|$EXECUTION_INTERVAL|g" \
    "$SCRIPT_DIR/etc/systemd/system/update-ddns.timer" > "$TEMP_DIR/update-ddns.timer"

# systemdディレクトリにコピー
sudo cp "$TEMP_DIR/update-ddns.service" /etc/systemd/system/
sudo cp "$TEMP_DIR/update-ddns.timer" /etc/systemd/system/

# 一時ディレクトリ削除
rm -rf "$TEMP_DIR"

# systemd設定
sudo systemctl daemon-reload
sudo systemctl enable update-ddns.timer
sudo systemctl start update-ddns.timer

echo "systemd設定が完了しました"
echo "実行間隔: $EXECUTION_INTERVAL"