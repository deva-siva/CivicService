#!/usr/bin/env bash
set -e

pip install -r requirements.txt

python manage.py makemigrations accounts
python manage.py makemigrations complaints
python manage.py makemigrations notifications
python manage.py makemigrations

python manage.py migrate --no-input
python manage.py collectstatic --no-input
