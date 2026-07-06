#!/usr/bin/env bash
set -euo pipefail

OFF_USER_ID=${1:-}
OFF_PASSWORD=${2:-}
CONTACT_EMAIL=${3:-}
USE_OFF_STAGING=${4:-false}

cat >.env <<EOF
OFF_USER_ID=${OFF_USER_ID}
OFF_PASSWORD=${OFF_PASSWORD}
CONTACT_EMAIL=${CONTACT_EMAIL}
USE_OFF_STAGING=${USE_OFF_STAGING}
EOF

echo "Injected .env (${#OFF_USER_ID} chars user, ${#OFF_PASSWORD} chars password)"
