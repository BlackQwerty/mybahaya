#!/usr/bin/env bash
# ============================================================
# deploy.sh — Foolproof backend deploy to the Hetzner server.
# Recompiles inside Docker from fresh source (the Dockerfile is
# a multi-stage build, so copying app.jar does NOTHING — only
# the src/ folder matters).
#
# Usage:  cd mybahaya-backend && ./deploy.sh
# ============================================================
set -e

SERVER="root@178.105.158.80"
REMOTE_DIR="/opt/mybahaya"

echo "▶ 1/4  Wiping stale source on server (avoids nested src/src)…"
ssh "$SERVER" "rm -rf $REMOTE_DIR/src $REMOTE_DIR/.mvn"

echo "▶ 2/4  Copying fresh build context…"
scp -r src     "$SERVER:$REMOTE_DIR/src"
scp -r .mvn    "$SERVER:$REMOTE_DIR/.mvn"
scp pom.xml mvnw "$SERVER:$REMOTE_DIR/"

echo "▶ 3/4  Rebuilding & restarting container (compiles inside Docker, ~2-3 min)…"
ssh "$SERVER" "cd $REMOTE_DIR && docker compose up -d --build"

echo "▶ 4/4  Verifying the new code is live…"
sleep 4
if ssh "$SERVER" "docker logs mybahaya-backend 2>&1 | grep -q MYBAHAYA_BUILD"; then
  ssh "$SERVER" "docker logs mybahaya-backend 2>&1 | grep MYBAHAYA_BUILD | tail -1"
  echo "✅ DEPLOY SUCCESS — new backend is running."
  echo "   Now make a NEW report to test (old reports won't have the new fields)."
else
  echo "⚠️  Could not find the build marker yet — container may still be starting."
  echo "   Check manually:  ssh $SERVER \"docker logs mybahaya-backend --tail 30\""
fi
