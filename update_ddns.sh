#!/bin/bash

# pyenv 初期化
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# 設定ファイル読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# venv activate
source "$PROJECT_PATH/.venv/bin/activate"
DATETIME=$(date +%F_%T)

# 現在のグローバルIPを取得
CURRENT_IP=$(curl -s https://checkip.amazonaws.com)

# 既存のAレコードを取得
OLD_IP=$(aws route53 list-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --query "ResourceRecordSets[?Name == '$RECORD_NAME' && Type == 'A'].ResourceRecords[0].Value" \
  --output text)

# 変更があるときのみ更新
if [ "$CURRENT_IP" != "$OLD_IP" ]; then
  echo "IPが変更されています: $OLD_IP → $CURRENT_IP"

  cat > /tmp/route53-ddns.json <<EOF
{
  "Comment": "DDNS update $DATETIME",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$RECORD_NAME",
      "Type": "A",
      "TTL": $TTL,
      "ResourceRecords": [{"Value": "$CURRENT_IP"}]
    }
  }]
}
EOF

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch file:///tmp/route53-ddns.json
fi
