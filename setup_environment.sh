#!/bin/bash

set -e

echo "Route53 DDNS Tools 環境セットアップを開始します..."

# プロジェクトディレクトリの確認
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "プロジェクトディレクトリ: $PROJECT_DIR"

# pyenvの確認とインストール
if [ ! -d "$HOME/.pyenv" ] && ! command -v pyenv &> /dev/null; then
    echo "pyenvがインストールされていません。インストールしますか? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        curl https://pyenv.run | bash
        
        # シェル設定ファイルに追加
        SHELL_RC="$HOME/.bashrc"
        if [ -n "$ZSH_VERSION" ]; then
            SHELL_RC="$HOME/.zshrc"
        fi
        
        echo '' >> "$SHELL_RC"
        echo '# pyenv' >> "$SHELL_RC"
        echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> "$SHELL_RC"
        echo 'eval "$(pyenv init --path)"' >> "$SHELL_RC"
        echo 'eval "$(pyenv init -)"' >> "$SHELL_RC"
        echo 'eval "$(pyenv virtualenv-init -)"' >> "$SHELL_RC"
        
        echo "pyenvをインストールし、シェル設定を更新しました。"
        echo "シェルを再起動してから再実行してください。"
        exit 0
    else
        echo "pyenvが必要です。手動でインストールしてください。"
        exit 1
    fi
fi

# pyenv初期化
if [ -d "$HOME/.pyenv" ]; then
    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

# Python 3.9以上の確認
PYTHON_VERSION=$(pyenv versions --bare | grep -E '^3\.(9|[1-9][0-9])' | head -1)
if [ -z "$PYTHON_VERSION" ]; then
    echo "Python 3.9以上をインストールします..."
    pyenv install 3.11.0
    PYTHON_VERSION="3.11.0"
fi

echo "使用するPythonバージョン: $PYTHON_VERSION"

# 仮想環境の作成
cd "$PROJECT_DIR"
if [ ! -d ".venv" ]; then
    echo "Python仮想環境を作成します..."
    pyenv local "$PYTHON_VERSION"
    python -m venv .venv
fi

# 仮想環境のアクティベート
source .venv/bin/activate

# 必要なパッケージのインストール（AWS CLIが必要な場合）
if ! command -v aws &> /dev/null; then
    echo "AWS CLIをインストールします..."
    pip install awscli
fi

# 設定ファイルの作成
if [ ! -f "config.sh" ]; then
    echo "設定ファイルを作成します..."
    cp config.sh.sample config.sh
    
    # PROJECT_PATHを自動設定
    sed -i "s|PROJECT_PATH=\"/path/to/r53_ddns_tools\"|PROJECT_PATH=\"$PROJECT_DIR\"|g" config.sh
    
    echo "config.shを編集して以下の設定を行ってください:"
    echo "  - ZONE_ID: Route53のゾーンID"
    echo "  - RECORD_NAME: 更新するレコード名"
    echo "  - EXECUTION_INTERVAL: 実行間隔（デフォルト: 5min）"
fi

echo ""
echo "環境セットアップが完了しました！"
echo ""
echo "次の手順:"
echo "1. AWS CLIの設定: aws configure"
echo "2. 設定ファイルの編集: vim config.sh"
echo "3. systemdサービスの有効化: ./setup_systemd.sh"