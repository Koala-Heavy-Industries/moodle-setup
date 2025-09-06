#!/bin/bash

# Moodle Docker環境を初期状態に戻すスクリプト

echo "=== Moodle Docker環境をリセット中 ==="

# 1. コンテナとネットワークを停止・削除
echo "1. コンテナとネットワークを停止・削除中..."
docker compose down -v

# 2. Dockerイメージを削除（完全再ビルドのため）
echo "2. Dockerイメージを削除中..."
docker rmi moodle-setup-php-fpm 2>/dev/null || echo "   イメージが存在しません（スキップ）"

# 3. ローカルのMoodleファイルとデータを削除
echo "3. ローカルファイルを削除中..."
docker run --rm -v $(pwd):/app -w /app alpine sh -c "
    rm -rf /app/moodle/* /app/moodledata/* /app/postgres_data/* 2>/dev/null || true
    # 隠しファイルも削除
    find /app/moodle -name '.*' ! -name '.' ! -name '..' -delete 2>/dev/null || true
    find /app/moodledata -name '.*' ! -name '.' ! -name '..' -delete 2>/dev/null || true
    find /app/postgres_data -name '.*' ! -name '.' ! -name '..' -delete 2>/dev/null || true
"

# 4. ディレクトリの状態確認
echo "4. ディレクトリの状態確認..."
echo "   moodleディレクトリ:"
ls -la moodle/ 2>/dev/null | head -3 || echo "   空のディレクトリ"
echo "   moodledataディレクトリ:"
ls -la moodledata/ 2>/dev/null | head -3 || echo "   空のディレクトリ"
echo "   postgres_dataディレクトリ:"
ls -la postgres_data/ 2>/dev/null | head -3 || echo "   空のディレクトリ"

# 5. Moodleプロジェクト関連のイメージのみクリーンアップ
echo "5. Moodleプロジェクト関連のイメージをクリーンアップ中..."
# 使用したイメージを削除（あれば）
docker rmi nginx:1.28 2>/dev/null && echo "   nginx:1.28 削除完了" || echo "   nginx:1.28 なし（スキップ）"
docker rmi postgres:16 2>/dev/null && echo "   postgres:16 削除完了" || echo "   postgres:16 なし（スキップ）"
docker rmi php:8.4-fpm 2>/dev/null && echo "   php:8.4-fpm 削除完了" || echo "   php:8.4-fpm なし（スキップ）"
docker rmi composer:latest 2>/dev/null && echo "   composer:latest 削除完了" || echo "   composer:latest なし（スキップ）"
docker rmi alpine:latest 2>/dev/null && echo "   alpine:latest 削除完了" || echo "   alpine:latest なし（スキップ）"

echo ""
echo "=== リセット完了 ==="
echo ""
echo "次のコマンドで新しい環境を起動できます:"
echo "  docker compose up -d --build"
echo ""
echo "起動後は以下にアクセスしてください:"
echo "  http://localhost:8080"