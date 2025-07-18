# تأكد من أنك في مجلد legal_rag
$basePath = "legal_rag"

# 1. تهيئة Alembic
Push-Location $basePath
alembic init app/db/migrations
Pop-Location

# 2. تعديل alembic.ini
$alembicIniPath = Join-Path $basePath "alembic.ini"
(Get-Content $alembicIniPath) -replace 'sqlalchemy.url =.*', 'sqlalchemy.url =' | Set-Content $alembicIniPath

# 3. تعديل env.py داخل migrations
$envPath = Join-Path $basePath "app/db/migrations/env.py"

$envContent = @'
import sys
import os
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context

# إعداد البيئة للوصول إلى app/
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../')))

from app.core.config import get_settings
from app.core.database import Base
from app.db.base import *  # ← استيراد جميع الموديلات

config = context.config
fileConfig(config.config_file_name)
target_metadata = Base.metadata

config.set_main_option("sqlalchemy.url", get_settings().DATABASE_URL)

def run_migrations_offline():
    context.configure(
        url=get_settings().DATABASE_URL,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)

        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
'@

Set-Content -Path $envPath -Value $envContent -Encoding UTF8

# 4. إنشاء base.py
$baseFile = Join-Path $basePath "app/db/base.py"
$baseContent = @"
from app.db.models.project import Project
from app.db.models.document import Document
"@
Set-Content -Path $baseFile -Value $baseContent -Encoding UTF8

Write-Host "✅ Alembic is now configured successfully!"
