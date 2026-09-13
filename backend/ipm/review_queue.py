"""
ipm/review_queue.py

The human-in-the-loop safety net: low-confidence disease/pest predictions
get queued here for a human expert to confirm or correct BEFORE a farmer
sees the advisory as settled fact.
"""

import json
import os
import uuid
from datetime import datetime, timezone


def _queue_path():
    """Always look for the queue file next to THIS script, regardless of
    which folder the command was run from."""
    this_folder = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(this_folder, "review_queue.json")


def _load_queue():
    """Returns an empty list if the file doesn't exist yet."""
    path = _queue_path()
    if not os.path.exists(path):
        return []
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return []


def _save_queue(queue):
    path = _queue_path()
    with open(path, "w", encoding="utf-8") as f:
        json.dump(queue, f, ensure_ascii=False, indent=2)


def needs_review(confidence: float, threshold: float = 0.6) -> bool:
    """Below this threshold, we don't trust the prediction enough to show
    it directly without flagging for review."""
    return confidence < threshold


def add_case(disease_or_pest_name: str, risk_level: str, language: str, confidence: float, image_url: str = None):
    """Adds a new case to the review queue. Returns the created case dict."""
    queue = _load_queue()

    case = {
        "case_id": str(uuid.uuid4())[:8],
        "disease_or_pest_name": disease_or_pest_name,
        "risk_level": risk_level,
        "language": language,
        "confidence": confidence,
        "image_url": image_url,
        "status": "pending",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "reviewed_at": None,
        "expert_notes": None,
        "corrected_disease_name": None,
    }

    queue.append(case)
    _save_queue(queue)
    return case


def list_pending():
    """Returns only cases still waiting for expert review."""
    queue = _load_queue()
    return [case for case in queue if case.get("status") == "pending"]


def resolve_case(case_id: str, decision: str, expert_notes: str = None, corrected_disease_name: str = None):
    """An expert calls this after reviewing a case.
    decision: "approved" or "corrected"."""
    if decision not in ("approved", "corrected"):
        raise ValueError("decision must be 'approved' or 'corrected'")

    queue = _load_queue()

    for case in queue:
        if case["case_id"] == case_id:
            case["status"] = decision
            case["reviewed_at"] = datetime.now(timezone.utc).isoformat()
            case["expert_notes"] = expert_notes
            if decision == "corrected":
                case["corrected_disease_name"] = corrected_disease_name
            _save_queue(queue)
            return case

    return None
