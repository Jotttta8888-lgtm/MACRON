#!/bin/bash
# MACRON Backup - Corre cada 24h via cron
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/Documents/MACRON/backups"
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/macron_backup_$DATE.tar.gz" \
  custom_commands.json \
  voice_history.json \
  .macron_key \
  favorites.json 2>/dev/null
# Mantener solo últimos 30 backups
ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +31 | xargs rm -f 2>/dev/null
echo "[Backup] Guardado: $BACKUP_DIR/macron_backup_$DATE.tar.gz"
