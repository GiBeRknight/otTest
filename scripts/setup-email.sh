#!/usr/bin/env bash
# =============================================================
# setup-email.sh — configure incoming (IMAP) and outgoing (SMTP)
# mail for Znuny / OTRS Community Edition
#
# Usage:
#   ./scripts/setup-email.sh
#
# Requirements:
#   - Docker containers must be running (docker compose up -d)
#   - Znuny must have completed its first-time installation
#   - .env file must exist with MAIL_* variables filled in
# =============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

# Load .env
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: .env file not found at $ENV_FILE"
  exit 1
fi
# shellcheck disable=SC1090
source "$ENV_FILE"

CONTAINER="otrs-app"
CONSOLE="/opt/otrs/bin/otrs.Console.pl"

echo "==> Waiting for Znuny container to be ready..."
until docker exec "$CONTAINER" test -f "$CONSOLE" 2>/dev/null; do
  echo "    ... still waiting"
  sleep 5
done

echo ""
echo "==> [1/4] Configuring outgoing mail (SMTP / Google Workspace)..."
docker exec "$CONTAINER" perl "$CONSOLE" Admin::Config::Update \
  --setting-name "SendmailModule" \
  --value "Kernel::System::Email::SMTPTLS"

docker exec "$CONTAINER" perl "$CONSOLE" Admin::Config::Update \
  --setting-name "SendmailModule::Host" \
  --value "${MAIL_SMTP_HOST:-smtp.gmail.com}"

docker exec "$CONTAINER" perl "$CONSOLE" Admin::Config::Update \
  --setting-name "SendmailModule::Port" \
  --value "${MAIL_SMTP_PORT:-587}"

docker exec "$CONTAINER" perl "$CONSOLE" Admin::Config::Update \
  --setting-name "SendmailModule::AuthUser" \
  --value "${MAIL_SMTP_USER}"

docker exec "$CONTAINER" perl "$CONSOLE" Admin::Config::Update \
  --setting-name "SendmailModule::AuthPassword" \
  --value "${MAIL_SMTP_PASSWORD}"

echo ""
echo "==> [2/4] Configuring system email address..."
docker exec "$CONTAINER" perl "$CONSOLE" Admin::Config::Update \
  --setting-name "AdminEmail" \
  --value "${MAIL_SMTP_USER}"

echo ""
echo "==> [3/4] Adding incoming mail account (IMAPS / Google Workspace)..."
# Check if account already exists to avoid duplicates
EXISTING=$(docker exec "$CONTAINER" perl "$CONSOLE" \
  Admin::MailAccount::List 2>/dev/null | grep "${MAIL_IMAP_USER}" || true)

if [[ -n "$EXISTING" ]]; then
  echo "    Mail account ${MAIL_IMAP_USER} already exists — skipping."
else
  docker exec "$CONTAINER" perl "$CONSOLE" Admin::MailAccount::Add \
    --login "${MAIL_IMAP_USER}" \
    --password "${MAIL_IMAP_PASSWORD}" \
    --host "${MAIL_IMAP_HOST:-imap.gmail.com}" \
    --type "IMAPS" \
    --queue "Raw" \
    --trusted 0 \
    --dispatching-by-email-to 0
  echo "    Mail account added: ${MAIL_IMAP_USER} via ${MAIL_IMAP_HOST}:${MAIL_IMAP_PORT}"
fi

echo ""
echo "==> [4/4] Rebuilding configuration cache..."
docker exec "$CONTAINER" perl "$CONSOLE" Maint::Config::Rebuild
docker exec "$CONTAINER" perl "$CONSOLE" Maint::Cache::Delete

echo ""
echo "======================================================"
echo "  Email configuration complete!"
echo ""
echo "  Outgoing SMTP : ${MAIL_SMTP_HOST}:${MAIL_SMTP_PORT}"
echo "  Incoming IMAP : ${MAIL_IMAP_HOST}:${MAIL_IMAP_PORT}"
echo "  Account       : ${MAIL_IMAP_USER}"
echo "======================================================"
echo ""
echo "  You can verify in Admin panel:"
echo "  http://localhost:${HTTP_PORT:-8080}/otrs/index.pl?Action=AdminEmail"
echo "  http://localhost:${HTTP_PORT:-8080}/otrs/index.pl?Action=AdminMailAccount"
