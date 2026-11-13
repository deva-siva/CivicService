import threading
import time
import requests
import logging
import os

logger = logging.getLogger(__name__)

def ping_url():
    # Use the app's own URL if provided in environment, otherwise skip
    url = os.getenv('RENDER_EXTERNAL_URL')
    if not url:
        # Fallback to the known URL if not set
        url = "https://civicservice.onrender.com"
    
    health_url = f"{url.rstrip('/')}/health/"
    interval = 240  # 4 minutes
    
    # Wait a bit for the server to start
    time.sleep(10)
    
    logger.info(f"Starting keep-alive pinger for {health_url}")
    
    while True:
        try:
            response = requests.get(health_url)
            # logger.info(f"Keep-alive ping status: {response.status_code}")
        except Exception as e:
            logger.error(f"Keep-alive ping failed: {e}")
        
        time.sleep(interval)

def start_pinger():
    # Only start pinger in production
    if os.getenv('RENDER'):
        thread = threading.Thread(target=ping_url, daemon=True)
        thread.start()
        logger.info("Keep-alive pinger thread started.")
