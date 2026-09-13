"""
advisory/routes.py — Module 5: IPM Advisory, Multilingual Support & Expert Validation

Backed by the IPM knowledge base via ipm/lookup.py, with a human-in-the-loop
safety net via ipm/review_queue.py for low-confidence cases.
"""

from fastapi import APIRouter, HTTPException, Query, Body
from typing import Optional
from pydantic import BaseModel

from schemas import AdvisoryRequest, AdvisoryResponse
from ipm.lookup import load_knowledge_base, get_advisory as lookup_advisory
from ipm.review_queue import needs_review, add_case, list_pending, resolve_case

router = APIRouter()

try:
    knowledge_base = load_knowledge_base()
except Exception as e:
    print(f"⚠️ Advisory KB load warning: {e}")
    knowledge_base = {"crops": {}}


class ResolveCaseRequest(BaseModel):
    case_id: str
    decision: str  # "approved" or "corrected"
    expert_notes: Optional[str] = None
    corrected_disease_name: Optional[str] = None


@router.post("/", response_model=AdvisoryResponse)
async def get_advisory(payload: AdvisoryRequest):
    """
    Get IPM advisory for a disease or pest.
    If confidence is below threshold (< 0.6), case is queued for expert review.
    """
    if payload.confidence is not None and needs_review(payload.confidence):
        case = add_case(
            payload.disease_or_pest_name,
            payload.risk_level.value,
            payload.language,
            payload.confidence,
        )
        return AdvisoryResponse(
            advisory_text=(
                f"This case has low prediction confidence ({payload.confidence:.0%}) "
                f"and has been queued for expert review (reference #{case['case_id']}). "
                f"The guidance below is general and preliminary — please do not treat "
                f"it as a confirmed diagnosis yet."
            ),
            ipm_steps=[
                "Monitor the affected crop closely and take clear photos from multiple angles.",
                "Avoid applying any chemical treatment until confirmed by an expert.",
                "Check back once expert review is complete for confirmed guidance.",
            ],
            language=payload.language,
            expert_validated=False,
            under_expert_review=True,
            review_case_id=case["case_id"],
        )

    result = lookup_advisory(
        knowledge_base,
        payload.disease_or_pest_name,
        payload.risk_level.value,
        payload.language,
    )
    return AdvisoryResponse(**result)


@router.get("/pending")
async def get_pending_cases():
    """
    Endpoint for Extension Officers/Experts to list all pending review cases.
    """
    return {"pending_cases": list_pending()}


@router.post("/resolve")
async def resolve_expert_case(payload: ResolveCaseRequest):
    """
    Endpoint for Experts to approve or correct a queued low-confidence case.
    """
    try:
        updated_case = resolve_case(
            case_id=payload.case_id,
            decision=payload.decision,
            expert_notes=payload.expert_notes,
            corrected_disease_name=payload.corrected_disease_name,
        )
        if not updated_case:
            raise HTTPException(status_code=404, detail="Case ID not found in review queue")
        return {"status": "success", "case": updated_case}
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
