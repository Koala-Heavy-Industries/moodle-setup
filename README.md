# Moodle Docker環境構築

## 環境構成
- Moodle 5.0.2
- PostgreSQL 16
- PHP 8.4 (PHP-FPM)
- Nginx 1.28

## セットアップ手順

### 1. 環境変数の設定
`.env`ファイルを確認し、必要に応じて編集してください：
```bash
DB_NAME=moodle          # データベース名
DB_USER=moodleuser      # データベースユーザー
DB_PASSWORD=moodlepassword  # データベースパスワード
MOODLE_URL=http://localhost:8080  # MoodleのURL
NGINX_PORT=8080         # Nginxのポート番号
```

### 2. Dockerコンテナの起動
```bash
# コンテナをビルドして起動（Moodleは自動的にダウンロードされます）
docker-compose up -d --build

# ログを確認
docker-compose logs -f
```

### 3. Webインストーラーでの設定
1. ブラウザで `http://localhost:8080` にアクセス
2. インストーラーの指示に従って設定：
   - 言語選択
   - データディレクトリ: `/var/moodledata`
   - データベース設定:
     - タイプ: PostgreSQL
     - ホスト: `postgres`
     - データベース名: `moodle`
     - ユーザー名: `moodleuser`
     - パスワード: `moodlepassword`
     - テーブル接頭辞: `mdl_`（デフォルト）
   - 管理者アカウントの作成

## 便利なコマンド

### コンテナの管理
```bash
# 起動
docker-compose up -d

# 停止
docker-compose down

# 再起動
docker-compose restart

# ログ確認
docker-compose logs -f [service-name]
```

### PHPコンテナへのアクセス
```bash
docker-compose exec php-fpm bash
```

### データベースへのアクセス
```bash
docker-compose exec postgres psql -U moodleuser -d moodle
```

## トラブルシューティング

### 権限エラーが発生する場合
```bash
# moodledataディレクトリの権限を修正
docker-compose exec php-fpm chown -R www-data:www-data /var/moodledata
docker-compose exec php-fpm chmod -R 777 /var/moodledata
```

### データベース接続エラー
- `.env`ファイルの設定を確認
- PostgreSQLコンテナが正常に起動しているか確認
```bash
docker-compose ps
docker-compose logs postgres
```

### Moodleが表示されない
- Nginxのログを確認
```bash
docker-compose logs nginx
```
- PHP-FPMのログを確認
```bash
docker-compose logs php-fpm
```

## データのバックアップ

### データベースのバックアップ
```bash
docker-compose exec postgres pg_dump -U moodleuser moodle > backup.sql
```

### Moodleファイルのバックアップ
```bash
tar -czf moodle-backup.tar.gz moodle/ moodledata/
```

## クリーンアップ

### 全てのデータを削除して最初からやり直す場合
```bash
# コンテナとボリュームを削除
docker-compose down -v

# ローカルのMoodleファイルを削除
rm -rf moodle/* moodledata/*
```