"""Groq AI client for NLP-based complaint classification"""
import os
import json
from groq import Groq
from django.conf import settings

_client = None


def get_groq_client():
    global _client
    if _client is None:
        api_key = getattr(settings, 'GROQ_API_KEY', os.getenv('GROQ_API_KEY', ''))
        if api_key:
            _client = Groq(api_key=api_key)
    return _client


def classify_with_groq(title: str, description: str) -> dict:
    """
    Use Groq LLM to classify complaint into category and department.
    Returns: {category, department, confidence, keywords, summary}
    """
    client = get_groq_client()
    if not client:
        return None

    prompt = f"""You are an AI assistant for a civic grievance management system in India.
Analyze the following complaint and respond with a JSON object only.

Complaint Title: {title}
Complaint Description: {description}

Respond with ONLY this JSON (no extra text):
{{
  "category": "<one of: road_pothole, water_leakage, drainage, street_light, garbage_sanitation, others>",
  "department": "<department name: Public Works, Water Supply, Sanitation, Electrical, Transport, or Others>",
  "confidence": <0.0 to 1.0>,
  "keywords": ["keyword1", "keyword2"],
  "urgency_keywords": ["any urgent keywords found"],
  "summary": "<one sentence summary in English>"
}}"""

    try:
        response = client.chat.completions.create(
            model="llama3-70b-8192",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.1,
            max_tokens=300,
        )
        content = response.choices[0].message.content.strip()
        # Extract JSON
        if '```json' in content:
            content = content.split('```json')[1].split('```')[0].strip()
        elif '```' in content:
            content = content.split('```')[1].split('```')[0].strip()
        return json.loads(content)
    except Exception as e:
        print(f"Groq classification error: {e}")
        return None


def translate_with_groq(text: str, target_language: str) -> str:
    """Translate text to target Indian language using Groq"""
    client = get_groq_client()
    if not client:
        return text

    lang_names = {
        'hi': 'Hindi', 'ta': 'Tamil', 'te': 'Telugu', 'kn': 'Kannada',
        'ml': 'Malayalam', 'mr': 'Marathi', 'gu': 'Gujarati', 'pa': 'Punjabi',
        'bn': 'Bengali', 'or': 'Odia', 'as': 'Assamese', 'ur': 'Urdu',
    }
    lang_name = lang_names.get(target_language, 'Hindi')

    try:
        response = client.chat.completions.create(
            model="llama3-70b-8192",
            messages=[{
                "role": "user",
                "content": f"Translate the following text to {lang_name}. Return only the translation:\n\n{text}"
            }],
            temperature=0.1,
            max_tokens=500,
        )
        return response.choices[0].message.content.strip()
    except Exception:
        return text
