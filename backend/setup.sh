#!/bin/bash
# Setup script for AI-Assisted Smart Grievance Platform Backend

echo "=== Setting up Smart Grievance Platform Backend ==="

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt

# Configure Cloudinary
echo "Cloudinary configured: dxeipgxvq"

# Download NLTK data
python3 -c "import nltk; nltk.download('punkt'); nltk.download('stopwords'); nltk.download('wordnet')"

# Copy env file
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env file - please update with your credentials"
fi

# Run migrations
python3 manage.py makemigrations accounts
python3 manage.py makemigrations complaints
python3 manage.py makemigrations notifications
python3 manage.py makemigrations
python3 manage.py migrate

# Seed default data (departments, permissions, admin user)
echo "Seeding initial data..."
python3 manage.py seed_data

# Collect static files
python3 manage.py collectstatic --noinput

echo "=== Setup complete! ==="
echo ""
echo "Admin credentials:"
echo "  Email:    admin@smartgrievance.in"
echo "  Password: Admin@1234"
echo ""
echo "Run: source venv/bin/activate && python manage.py runserver 0.0.0.0:8000"
