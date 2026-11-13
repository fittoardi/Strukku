from fastapi import APIRouter, HTTPException
from app.schemas import ParseReceiptRequest, ParsedReceiptResponse
from app.services.llm_parser import parse_receipt_with_llm

router = APIRouter(prefix="/api", tags=["Parser Struk"])


@router.post("/parse-receipt", response_model=ParsedReceiptResponse)
async def parse_receipt(payload: ParseReceiptRequest):
    if not payload.ocr_text.strip():
        raise HTTPException(status_code=400, detail="Teks OCR tidak boleh kosong")

    if len(payload.ocr_text) > 8000:
        raise HTTPException(status_code=400, detail="Teks OCR melebihi batas 8000 karakter")

    result = await parse_receipt_with_llm(payload.ocr_text)
    return result

