#!/bin/bash
set -e

# Moodleをダウンロード（index.phpが存在しない場合）
if [ ! -f /var/www/html/index.php ]; then
    echo "Moodleファイルが見つかりません。ダウンロード中..."
    cd /tmp
    wget --no-check-certificate https://download.moodle.org/download.php/direct/stable500/moodle-latest-500.tgz -O moodle.tgz
    tar -xzf moodle.tgz --strip-components=1 -C /var/www/html/
    rm -f moodle.tgz
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    echo "Moodleダウンロード完了"
fi

# Moodle config.phpの自動設定（無効化してインストーラーを使用）
if false && [ ! -f /var/www/html/config.php ] && [ -n "$DB_HOST" ]; then
    cat > /var/www/html/config.php <<EOF
<?php  // Moodle configuration file

unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

\$CFG->dbtype    = '${DB_TYPE:-pgsql}';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = '${DB_HOST}';
\$CFG->dbname    = '${DB_NAME}';
\$CFG->dbuser    = '${DB_USER}';
\$CFG->dbpass    = '${DB_PASSWORD}';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => ${DB_PORT:-5432},
  'dbsocket' => '',
);

\$CFG->wwwroot   = '${MOODLE_URL}';
\$CFG->dataroot  = '/var/moodledata';
\$CFG->admin     = 'admin';

\$CFG->directorypermissions = 0777;

require_once(__DIR__ . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!
EOF
    echo "config.php created with wwwroot=${MOODLE_URL}"
fi

# Execute the original command
exec "$@"