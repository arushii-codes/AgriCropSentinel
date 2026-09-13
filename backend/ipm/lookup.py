"""
ipm/lookup.py

Built against the real contract in schemas.py:

    class AdvisoryRequest(BaseModel):
        disease_or_pest_name: str
        risk_level: RiskLevel        # "low" | "medium" | "high" | "critical"
        language: str = "en"

    class AdvisoryResponse(BaseModel):
        advisory_text: str
        ipm_steps: list[str]
        language: str
        expert_validated: bool
"""

import json
import os


def load_knowledge_base(path=None):
    """Load the JSON file once into a Python dict."""
    if path is None:
        this_folder = os.path.dirname(os.path.abspath(__file__))
        path = os.path.join(this_folder, "ipm_knowledge_base.json")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def normalize_name(name: str) -> str:
    """Turns "Rice Blast" into "rice_blast" so it matches our JSON keys."""
    return name.strip().lower().replace(" ", "_").replace("-", "_")


def find_disease_entry(kb, disease_or_pest_name):
    """
    Searches across ALL crops for a matching disease id or common name.
    Returns: (crop_name, disease_entry_dict) or (None, None) if not found.
    """
    target = normalize_name(disease_or_pest_name)

    for crop_name, crop_data in kb["crops"].items():
        for disease_id, entry in crop_data["diseases"].items():
            if disease_id == target:
                return crop_name, entry
            if normalize_name(entry["disease_name_common"]) == target:
                return crop_name, entry

    return None, None


def risk_level_to_categories(risk_level: str):
    """Maps a risk_level word to which recommendation categories to show."""
    mapping = {
        "low": ["monitoring"],
        "medium": ["monitoring", "cultural"],
        "high": ["monitoring", "cultural", "biological", "mechanical"],
        "critical": ["monitoring", "cultural", "biological", "mechanical", "chemical"],
    }
    return mapping.get(risk_level, ["monitoring"])


def get_advisory(kb, disease_or_pest_name: str, risk_level: str, language: str = "en"):
    """Main function — return shape matches AdvisoryResponse fields exactly."""
    crop_name, entry = find_disease_entry(kb, disease_or_pest_name)

    if entry is None:
        return {
            "advisory_text": (
                f"No specific knowledge base entry found for '{disease_or_pest_name}' yet. "
                f"Showing general precautionary guidance."
            ),
            "ipm_steps": [
                "Monitor the affected crop closely over the next few days.",
                "Isolate or mark the affected area if possible.",
                "Consult your local agricultural extension officer for confirmation.",
            ],
            "language": language,
            "expert_validated": False,
        }

    categories = risk_level_to_categories(risk_level)

    translations = entry.get("translations", {})
    used_translation = False

    if language != "en" and language in translations:
        translated_entry = translations[language]
        disease_display_name = translated_entry.get("disease_name_common", entry["disease_name_common"])
        translated_recs = translated_entry.get("recommendations", {})

        ipm_steps = []
        for category in categories:
            for step_text in translated_recs.get(category, []):
                ipm_steps.append(step_text)

        used_translation = True
    else:
        disease_display_name = entry["disease_name_common"]
        ipm_steps = []
        for category in categories:
            for rec in entry["recommendations"].get(category, []):
                ipm_steps.append(rec["step"])

    advisory_text = (
        f"{disease_display_name} — risk level: {risk_level}. "
        f"Follow the steps below in order; later steps are more intensive "
        f"and should only be used if earlier ones aren't containing the issue."
    )

    if language != "en" and not used_translation:
        advisory_text += " (Note: translation not yet available for this disease — showing English.)"

    return {
        "advisory_text": advisory_text,
        "ipm_steps": ipm_steps,
        "language": language,
        "expert_validated": entry["validation_status"] == "expert-validated",
    }


if __name__ == "__main__":
    kb = load_knowledge_base()

    print("--- TEST 1: exact common name, medium risk ---")
    print(json.dumps(get_advisory(kb, "Rice Blast", "medium", "en"), indent=2, ensure_ascii=False))

    print("\n--- TEST 2: messy casing/spacing, critical risk ---")
    print(json.dumps(get_advisory(kb, "  cotton bollworm ", "critical", "en"), indent=2, ensure_ascii=False))

    print("\n--- TEST 3: unknown disease name (should NOT crash) ---")
    print(json.dumps(get_advisory(kb, "Some Made Up Disease", "high", "en"), indent=2, ensure_ascii=False))

    print("\n--- TEST 4: Hindi translation, Rice Blast, high risk ---")
    print(json.dumps(get_advisory(kb, "Rice Blast", "high", "hi"), indent=2, ensure_ascii=False))

    print("\n--- TEST 5: Punjabi translation, Rice Blast, low risk ---")
    print(json.dumps(get_advisory(kb, "Rice Blast", "low", "pa"), indent=2, ensure_ascii=False))

    print("\n--- TEST 6: Hindi requested, but Wheat has NO translation yet (should fall back to English + note) ---")
    print(json.dumps(get_advisory(kb, "Yellow Rust (Stripe Rust)", "high", "hi"), indent=2, ensure_ascii=False))