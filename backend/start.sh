#!/bin/sh
set -eu
cd "$(dirname "$0")"
if [ ! -x .venv/bin/python ]; then
  echo 'Backend environment missing. Follow docs/AI_FRONTEND_INTEGRATION.md first.' >&2
  exit 1
fi
exec .venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
