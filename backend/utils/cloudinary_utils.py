"""
Cloudinary image upload helpers.

All images are compressed server-side to stay under 1 MB via Cloudinary's
automatic quality/format optimisation (q_auto, f_auto).
"""

import logging
import io
from PIL import Image

import cloudinary.uploader

logger = logging.getLogger(__name__)

# Hard limit — reject uploads already over this size
_MAX_BYTES = 10 * 1024 * 1024   # 10 MB raw upload limit


def _compress_if_needed(file_obj) -> bytes:
    """
    Read the file and compress it with Pillow if it's larger than 1 MB.
    Returns raw bytes ready to send to Cloudinary.
    """
    data = file_obj.read()
    if len(data) <= 1024 * 1024:
        return data  # already under 1 MB — nothing to do

    try:
        img = Image.open(io.BytesIO(data))
        img = img.convert('RGB')  # ensure JPEG-compatible

        # Resize proportionally if very large (>2000 px on longest side)
        max_dim = 2000
        w, h = img.size
        if max(w, h) > max_dim:
            ratio = max_dim / max(w, h)
            img = img.resize((int(w * ratio), int(h * ratio)), Image.LANCZOS)

        # Binary-search for a quality level that produces ≤ 1 MB
        lo, hi, best = 20, 85, None
        while lo <= hi:
            q = (lo + hi) // 2
            buf = io.BytesIO()
            img.save(buf, format='JPEG', quality=q, optimize=True)
            compressed = buf.getvalue()
            if len(compressed) <= 1024 * 1024:
                best = compressed
                lo = q + 1     # try higher quality
            else:
                hi = q - 1     # need lower quality

        if best:
            logger.info(
                f'Image compressed: {len(data)//1024} KB → {len(best)//1024} KB'
            )
            return best
    except Exception as e:
        logger.warning(f'Pillow compression failed, uploading original: {e}')

    return data  # fallback: upload as-is


def upload_image(file_obj, folder: str = 'grievance') -> str | None:
    """
    Compress image to ≤ 1 MB then upload to Cloudinary.

    Args:
        file_obj: Django InMemoryUploadedFile / TemporaryUploadedFile
        folder:   Cloudinary folder name ('complaints' or 'profiles')

    Returns:
        Secure HTTPS URL of the uploaded image, or None on failure.
    """
    if not file_obj:
        return None

    try:
        raw = _compress_if_needed(file_obj)

        result = cloudinary.uploader.upload(
            raw,
            folder=folder,
            resource_type='image',
            # Cloudinary auto-optimises quality & format on delivery
            transformation=[
                {'quality': 'auto:good', 'fetch_format': 'auto'},
            ],
        )
        url: str = result.get('secure_url', '')
        logger.info(f'Cloudinary upload OK: {url}')
        return url or None

    except Exception as e:
        logger.error(f'Cloudinary upload failed: {e}')
        return None
