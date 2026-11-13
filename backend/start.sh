#!/usr/bin/env bash
set -e

exec gunicorn grievance_platform.wsgi:application \
    --bind 0.0.0.0:${PORT:-8000} \
    --workers 2 \
    --timeout 120
