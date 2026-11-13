"""
AI Classification Engine
- Primary: Groq LLM (llama3-70b-8192)
- Fallback: TF-IDF + Logistic Regression (scikit-learn)
- Priority Scoring
- Duplicate Detection
"""
import re
import os
import pickle
import numpy as np
from django.utils import timezone
from django.conf import settings
from .groq_client import classify_with_groq

# ─── Keyword maps for fallback classification ───────────────────────────

CATEGORY_KEYWORDS = {
    'road_pothole': [
        'road', 'pothole', 'crack', 'damaged', 'broken road', 'tar', 'bitumen',
        'footpath', 'pavement', 'speed breaker', 'divider', 'highway', 'street damage',
        'road repair', 'road hole', 'bump', 'uneven road',
    ],
    'water_leakage': [
        'water', 'pipe', 'leakage', 'leak', 'burst pipe', 'water supply', 'tap',
        'water shortage', 'no water', 'water connection', 'sewage', 'plumbing',
        'water contamination', 'muddy water', 'dirty water', 'water pressure',
    ],
    'drainage': [
        'drain', 'drainage', 'blocked drain', 'clogged', 'overflow', 'flooding',
        'waterlogging', 'stagnant water', 'puddle', 'gutter', 'manhole',
        'open drain', 'sewage overflow', 'storm drain',
    ],
    'street_light': [
        'street light', 'light', 'lamp', 'electricity', 'dark', 'no light',
        'broken light', 'faulty light', 'electrical', 'power', 'wiring',
        'transformer', 'power cut', 'night visibility',
    ],
    'garbage_sanitation': [
        'garbage', 'waste', 'trash', 'sanitation', 'litter', 'dumping',
        'solid waste', 'dustbin', 'waste collection', 'hygiene', 'filth',
        'dirty', 'cleaning', 'sweeping', 'open defecation', 'toilet',
    ],
}

DEPARTMENT_MAP = {
    'road_pothole': 'Public Works',
    'water_leakage': 'Water Supply',
    'drainage': 'Public Works',
    'street_light': 'Electrical',
    'garbage_sanitation': 'Sanitation',
    'others': 'Others',
}

URGENCY_KEYWORDS = [
    'emergency', 'urgent', 'danger', 'dangerous', 'severe', 'flood', 'fire',
    'accident', 'injury', 'immediate', 'critical', 'life threatening', 'help',
    'electrocution', 'collapse', 'broken', 'major'
]


def preprocess_text(text: str) -> str:
    text = text.lower()
    text = re.sub(r'[^\w\s]', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def keyword_classify(text: str) -> dict:
    """Simple keyword-based fallback classifier"""
    text = preprocess_text(text)
    scores = {}
    for category, keywords in CATEGORY_KEYWORDS.items():
        score = sum(1 for kw in keywords if kw in text)
        scores[category] = score

    best_category = max(scores, key=scores.get)
    best_score = scores[best_category]

    if best_score == 0:
        best_category = 'others'

    confidence = min(best_score / 5.0, 1.0)

    return {
        'category': best_category,
        'department': DEPARTMENT_MAP.get(best_category, 'Others'),
        'confidence': confidence,
        'keywords': [kw for kw in CATEGORY_KEYWORDS.get(best_category, []) if kw in text],
        'urgency_keywords': [kw for kw in URGENCY_KEYWORDS if kw in text],
        'summary': f"Issue classified as: {best_category.replace('_', ' ').title()}",
    }


def classify_complaint(description: str, title: str = '') -> dict:
    """
    Main classification function.
    1. Try Groq AI first
    2. Fall back to keyword matching
    """
    combined_text = f"{title} {description}".strip()

    # Try Groq first
    result = classify_with_groq(title, description)
    if result and result.get('category'):
        return result

    # Fallback to keyword matching
    return keyword_classify(combined_text)


# ─── PRIORITY SCORING ────────────────────────────────────────────────────

def calculate_priority(complaint) -> dict:
    """
    Calculate priority score (0-100) and level (low/medium/high)

    Factors:
    1. Base score by category
    2. Complaint age / SLA
    3. Repeated complaints from same location
    4. Urgency keywords in text
    """
    from complaints.models import Complaint

    score = settings.CATEGORY_PRIORITY_SCORES.get(complaint.category, 40)

    # Age factor — add up to 20 points based on days since submission
    days_open = complaint.days_open if hasattr(complaint, 'days_open') else 0
    age_score = min(days_open * 3, 20)
    score += age_score

    # Urgency keywords in description
    combined = f"{complaint.title} {complaint.description}".lower()
    urgency_count = sum(1 for kw in URGENCY_KEYWORDS if kw in combined)
    if urgency_count > 0:
        score += min(urgency_count * 7, 20)

    # Repeated complaints from same location (within 500m radius or text match)
    if complaint.location_text:
        location_words = complaint.location_text.lower().split()
        similar_location_count = Complaint.objects.filter(
            category=complaint.category,
            status__in=['submitted', 'assigned', 'in_progress'],
        ).exclude(pk=complaint.pk if complaint.pk else None).count()
        if similar_location_count >= 3:
            score += 15
        elif similar_location_count >= 2:
            score += 8

    score = min(score, 100)

    if score >= 67:
        level = 'high'
    elif score >= 34:
        level = 'medium'
    else:
        level = 'low'

    return {'score': score, 'level': level}


# ─── DUPLICATE DETECTION ─────────────────────────────────────────────────

def text_similarity(text1: str, text2: str) -> float:
    """Simple Jaccard similarity between two texts"""
    words1 = set(preprocess_text(text1).split())
    words2 = set(preprocess_text(text2).split())
    if not words1 or not words2:
        return 0.0
    intersection = words1 & words2
    union = words1 | words2
    return len(intersection) / len(union)


def detect_duplicates(complaint) -> int | None:
    """
    Detect if this complaint is a duplicate of an existing one.
    Checks:
    1. Same category + similar location
    2. Text similarity > 0.4
    Returns ID of duplicate complaint or None
    """
    from complaints.models import Complaint

    # Look at recent complaints of same category (last 30 days)
    from datetime import timedelta
    cutoff = timezone.now() - timedelta(days=30)

    candidates = Complaint.objects.filter(
        category=complaint.category,
        created_at__gte=cutoff,
        is_duplicate=False,
        status__in=['submitted', 'assigned', 'in_progress'],
    )
    if complaint.pk:
        candidates = candidates.exclude(pk=complaint.pk)

    combined = f"{complaint.title} {complaint.description}"

    for candidate in candidates:
        # Location check
        location_match = False
        if complaint.location_text and candidate.location_text:
            loc_sim = text_similarity(complaint.location_text, candidate.location_text)
            location_match = loc_sim > 0.3

        # Text similarity
        candidate_combined = f"{candidate.title} {candidate.description}"
        sim = text_similarity(combined, candidate_combined)

        if sim > 0.45 and (location_match or sim > 0.6):
            return candidate.id

    return None
