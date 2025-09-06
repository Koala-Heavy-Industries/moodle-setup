# Moodle Docker環境 運用マニュアル

## 📋 目次
- [環境構成](#環境構成)
- [基本操作](#基本操作)
- [バックアップ](#バックアップ)
- [復旧](#復旧)
- [メンテナンス](#メンテナンス)
- [トラブルシューティング](#トラブルシューティング)
- [モニタリング](#モニタリング)

## 📊 環境構成

### システム構成
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Nginx       │    │    PHP-FPM      │    │   PostgreSQL    │
│   (Web Server)  │◄──►│  (Application)  │◄──►│   (Database)    │
│   Port: 8080    │    │    Moodle       │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### コンテナ情報
| コンテナ | イメージ | 役割 | ポート |
|---------|---------|------|---------|
| moodle_nginx | nginx:1.28 | Webサーバー | 8080→80 |
| moodle_php | moodle-setup-php-fpm | PHP-FPM + Moodle | 9000 |
| moodle_postgres | postgres:16 | データベース | 5432 |

### データ保存場所
- **Moodleファイル**: `moodle_files`ボリューム
- **Moodleデータ**: `./moodledata`ディレクトリ
- **データベース**: `./postgres_data`ディレクトリ

## 🚀 基本操作

### 初回セットアップ

```bash
# 1. リポジトリクローン
git clone <repository-url>
cd moodle-setup

# 2. 環境変数の確認・編集
cp .env .env.local  # 必要に応じて
vim .env.local

# 3. 環境起動
docker compose up -d --build

# 4. ブラウザアクセス
# http://localhost:8080
```

### 日常的な起動・停止

#### 🟢 起動
```bash
# 通常起動
docker compose up -d

# ログ確認しながら起動
docker compose up

# 特定のサービスのみ起動
docker compose up -d nginx php-fpm
```

#### 🔴 停止
```bash
# 全サービス停止
docker compose down

# データを保持して停止
docker compose stop

# 特定のサービスのみ停止
docker compose stop nginx
```

#### 🔄 再起動
```bash
# 全サービス再起動
docker compose restart

# 特定のサービスのみ再起動
docker compose restart php-fpm

# 設定変更後の再起動
docker compose down && docker compose up -d
```

### 完全リセット
```bash
# 全データを削除して初期化
./reset-docker.sh
docker compose up -d --build
```

## 💾 バックアップ

### 自動バックアップスクリプト

#### バックアップスクリプトの作成
```bash
# backup.shを作成
cat > backup.sh << 'EOF'
#!/bin/bash

# バックアップ設定
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
DB_CONTAINER="moodle_postgres"
DB_NAME="moodle"
DB_USER="moodleuser"

echo "=== Moodleバックアップ開始 ==="
mkdir -p "$BACKUP_DIR"

# 1. データベースバックアップ
echo "1. データベースをバックアップ中..."
docker compose exec -T postgres pg_dump -U $DB_USER $DB_NAME | gzip > "$BACKUP_DIR/database.sql.gz"

# 2. Moodledataバックアップ
echo "2. Moodledataをバックアップ中..."
tar -czf "$BACKUP_DIR/moodledata.tar.gz" moodledata/

# 3. PostgreSQLデータディレクトリバックアップ
echo "3. PostgreSQLデータをバックアップ中..."
sudo tar -czf "$BACKUP_DIR/postgres_data.tar.gz" postgres_data/

# 4. 設定ファイルバックアップ
echo "4. 設定ファイルをバックアップ中..."
tar -czf "$BACKUP_DIR/config.tar.gz" .env nginx/ php/ docker-compose.yml

# 5. バックアップ情報記録
echo "5. バックアップ情報を記録中..."
cat > "$BACKUP_DIR/backup_info.txt" << EOL
Backup Date: $(date)
Backup Directory: $BACKUP_DIR
Database: $DB_NAME
Components:
- database.sql.gz (Database dump)
- moodledata.tar.gz (Moodle data directory)
- postgres_data.tar.gz (PostgreSQL data directory)
- config.tar.gz (Configuration files)
EOL

# バックアップサイズ確認
echo "=== バックアップ完了 ==="
du -sh "$BACKUP_DIR"
ls -la "$BACKUP_DIR/"
EOF

chmod +x backup.sh
```

#### バックアップ実行
```bash
# 手動バックアップ
./backup.sh

# cron設定例（毎日深夜2時）
echo "0 2 * * * cd /path/to/moodle-setup && ./backup.sh" | crontab -
```

### 手動バックアップ

#### データベースのみ
```bash
# SQLダンプ作成
docker compose exec postgres pg_dump -U moodleuser moodle > backup_$(date +%Y%m%d).sql

# 圧縮版
docker compose exec postgres pg_dump -U moodleuser moodle | gzip > backup_$(date +%Y%m%d).sql.gz
```

#### ファイルのみ
```bash
# Moodledataバックアップ
tar -czf moodledata_$(date +%Y%m%d).tar.gz moodledata/

# 全データバックアップ
tar -czf moodle_full_$(date +%Y%m%d).tar.gz moodledata/ postgres_data/
```

## 🔄 復旧

### 完全復旧手順

```bash
# 1. 現在の環境停止
docker compose down -v

# 2. 古いデータ削除
./reset-docker.sh

# 3. バックアップからデータ復旧
BACKUP_DIR="backups/20241201_140000"  # バックアップディレクトリを指定

# データベース復旧
gunzip -c "$BACKUP_DIR/database.sql.gz" | docker compose exec -T postgres psql -U moodleuser -d moodle

# Moodledata復旧
tar -xzf "$BACKUP_DIR/moodledata.tar.gz"

# PostgreSQLデータ復旧
sudo tar -xzf "$BACKUP_DIR/postgres_data.tar.gz"

# 設定ファイル復旧
tar -xzf "$BACKUP_DIR/config.tar.gz"

# 4. 環境起動
docker compose up -d --build
```

### 部分復旧

#### データベースのみ復旧
```bash
# 1. データベースクリア
docker compose exec postgres psql -U moodleuser -d moodle -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

# 2. バックアップ復旧
gunzip -c backup_20241201.sql.gz | docker compose exec -T postgres psql -U moodleuser -d moodle
```

## 🔧 メンテナンス

### 定期メンテナンス

#### ログローテーション
```bash
# Dockerログのサイズ制限（docker-compose.yml）
logging:
  driver: "json-file"
  options:
    max-size: "100m"
    max-file: "5"
```

#### 不要なDockerリソースクリーンアップ
```bash
# 週次クリーンアップ
docker system prune -f
docker volume prune -f
```

### Moodleアップデート

#### アップデート手順
```bash
# 1. 現在のバージョン確認
docker compose exec php-fpm php /var/www/html/admin/cli/maintenance.php --enable

# 2. バックアップ作成
./backup.sh

# 3. Moodleファイル更新（新バージョンのDockerfileを使用）
./reset-docker.sh
docker compose up -d --build

# 4. データベースアップデート（Web UIまたはCLI）
docker compose exec php-fpm php /var/www/html/admin/cli/upgrade.php --non-interactive

# 5. メンテナンスモード解除
docker compose exec php-fpm php /var/www/html/admin/cli/maintenance.php --disable
```

### データベースメンテナンス

```bash
# データベース統計情報更新
docker compose exec postgres psql -U moodleuser -d moodle -c "ANALYZE;"

# 不要データ削除（VACUUMスクリプト例）
cat > db_maintenance.sh << 'EOF'
#!/bin/bash
docker compose exec postgres psql -U moodleuser -d moodle << SQL
-- セッションクリーンアップ
DELETE FROM mdl_sessions WHERE timemodified < extract(epoch FROM now() - interval '1 week');
-- ログクリーンアップ
DELETE FROM mdl_logstore_standard_log WHERE timecreated < extract(epoch FROM now() - interval '3 months');
-- VACUUM実行
VACUUM ANALYZE;
SQL
EOF
chmod +x db_maintenance.sh
```

## 🔍 モニタリング

### リアルタイム監視

#### システム状態確認
```bash
# コンテナ状態
docker compose ps

# リソース使用状況
docker stats

# ログ監視
docker compose logs -f --tail=50

# 特定サービスのログ
docker compose logs -f php-fpm
```

#### パフォーマンス監視
```bash
# データベース接続確認
docker compose exec postgres psql -U moodleuser -d moodle -c "SELECT version();"

# Moodle状態確認
curl -I http://localhost:8080/

# ディスク使用量確認
docker system df
du -sh postgres_data/ moodledata/
```

### ログ分析

#### Nginxアクセスログ
```bash
# アクセス状況確認
docker compose exec nginx tail -f /var/log/nginx/access.log

# エラーログ確認
docker compose exec nginx tail -f /var/log/nginx/error.log
```

#### PHPエラーログ
```bash
# PHP-FPMログ
docker compose logs php-fpm | grep ERROR

# Moodleログ
docker compose exec php-fpm tail -f /var/moodledata/moodledata.log
```

## 🚨 トラブルシューティング

### よくある問題と対処法

#### 1. 403 Forbidden エラー
```bash
# 原因: Moodleファイルが存在しない
# 対処法:
docker compose exec -u root php-fpm /usr/local/bin/docker-entrypoint.sh echo "check"
docker compose restart php-fpm
```

#### 2. データベース接続エラー
```bash
# 原因: PostgreSQLが起動していない
# 対処法:
docker compose logs postgres
docker compose restart postgres
```

#### 3. 権限エラー
```bash
# moodledata権限修正
docker compose exec -u root php-fpm chown -R www-data:www-data /var/moodledata
docker compose exec -u root php-fpm chmod -R 777 /var/moodledata
```

#### 4. ディスク容量不足
```bash
# 不要なDockerデータ削除
docker system prune -a
docker volume prune

# 古いログ削除
docker compose exec nginx sh -c "echo > /var/log/nginx/access.log"
```

### 緊急時対応

#### サービス復旧優先度
1. **PostgreSQL** (データベース)
2. **PHP-FPM** (Moodleアプリケーション)
3. **Nginx** (Webサーバー)

#### 緊急復旧手順
```bash
# 1. 全サービス停止
docker compose down

# 2. 最新バックアップから復旧
# (復旧手順セクション参照)

# 3. サービス個別起動
docker compose up -d postgres
# PostgreSQL起動確認後
docker compose up -d php-fpm
# PHP-FPM起動確認後
docker compose up -d nginx
```

## 📞 サポート情報

### 設定ファイル場所
- **Docker Compose**: `docker-compose.yml`
- **環境変数**: `.env`
- **Nginx設定**: `nginx/default.conf`
- **PHP設定**: `php/Dockerfile`内

### 重要なコマンド集
```bash
# 状態確認
docker compose ps
docker compose logs --tail=50

# 緊急停止
docker compose down

# 完全リセット
./reset-docker.sh

# バックアップ
./backup.sh

# 設定反映
docker compose down && docker compose up -d
```

### ログファイル場所
- **コンテナログ**: `docker compose logs [service]`
- **Moodleログ**: `/var/moodledata/` (コンテナ内)
- **PostgreSQLログ**: `docker compose logs postgres`

---

**📝 注意事項:**
- 本番環境では必ず事前にバックアップを作成してください
- 定期的なバックアップとテスト復旧を実施してください
- セキュリティアップデートを定期的に適用してください

**📅 更新履歴:**
- v1.0: 初版作成 (2025-01-XX)