from datetime import date, datetime
from typing import List, Optional
from uuid import UUID
from pydantic import BaseModel, Field


# --- Schema Parser Struk ---

class ReceiptItem(BaseModel):
    nama: str
    qty: int = 1
    harga_satuan: int = 0
    subtotal: int = 0


class ParsedReceiptResponse(BaseModel):
    nama_toko: Optional[str] = None
    tanggal: Optional[str] = None
    items: List[ReceiptItem] = []
    subtotal: Optional[int] = 0
    pajak: int = 0
    diskon: int = 0
    total: Optional[int] = 0
    kategori_saran: str = "Lainnya"
    confidence: float = 0.0
    catatan_parser: Optional[str] = None


class ParseReceiptRequest(BaseModel):
    ocr_text: str = Field(..., max_length=10000, description="Teks mentah hasil OCR")


# --- Schema Transaksi ---

class TransactionItemCreate(BaseModel):
    id: Optional[UUID] = None
    nama_item: str
    qty: int = 1
    harga_satuan: int
    subtotal: int


class TransactionItemResponse(BaseModel):
    id: UUID
    transaction_id: UUID
    nama_item: str
    qty: int
    harga_satuan: int
    subtotal: int

    class Config:
        from_attributes = True


class TransactionCreate(BaseModel):
    id: Optional[UUID] = None
    user_id: Optional[UUID] = None
    wallet_id: Optional[UUID] = None
    category_id: Optional[UUID] = None
    tipe: str = "keluar"  # 'masuk' | 'keluar'
    total: int
    tanggal: date
    nama_toko: Optional[str] = None
    catatan: Optional[str] = None
    foto_struk_path: Optional[str] = None
    sumber: str = "manual"  # 'scan' | 'manual'
    confidence: Optional[float] = None
    items: List[TransactionItemCreate] = []


class TransactionResponse(BaseModel):
    id: UUID
    user_id: UUID
    wallet_id: Optional[UUID]
    category_id: Optional[UUID]
    tipe: str
    total: int
    tanggal: date
    nama_toko: Optional[str]
    catatan: Optional[str]
    foto_struk_path: Optional[str]
    sumber: str
    confidence: Optional[float]
    created_at: datetime
    updated_at: datetime
    items: List[TransactionItemResponse] = []

    class Config:
        from_attributes = True


# --- Schema Kategori & Dompet ---

class CategoryResponse(BaseModel):
    id: UUID
    nama: str
    ikon: str
    warna: str
    tipe: str
    is_default: bool

    class Config:
        from_attributes = True


class WalletResponse(BaseModel):
    id: UUID
    nama: str
    tipe: str
    saldo_awal: int

    class Config:
        from_attributes = True

