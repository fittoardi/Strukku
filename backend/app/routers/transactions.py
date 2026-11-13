import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from app.database import get_db
from app.models import Transaction, TransactionItem, User
from app.schemas import TransactionCreate, TransactionResponse

router = APIRouter(prefix="/api/transactions", tags=["Transaksi"])

# Default User ID untuk mode single-user/lokal
DEFAULT_USER_ID = uuid.UUID("00000000-0000-0000-0000-000000000001")


def ensure_default_user(db: Session):
    user = db.query(User).filter(User.id == DEFAULT_USER_ID).first()
    if not user:
        user = User(id=DEFAULT_USER_ID, nama="Pengguna Lokal", mata_uang="IDR")
        db.add(user)
        db.commit()


@router.get("", response_model=List[TransactionResponse])
def get_transactions(
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    ensure_default_user(db)
    query = (
        db.query(Transaction)
        .options(joinedload(Transaction.items))
        .filter(Transaction.deleted_at.is_(None))
        .order_by(Transaction.tanggal.desc(), Transaction.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    return query.all()


@router.post("", response_model=TransactionResponse)
def create_transaction(
    payload: TransactionCreate,
    db: Session = Depends(get_db),
):
    ensure_default_user(db)
    tx_id = payload.id or uuid.uuid4()
    user_id = payload.user_id or DEFAULT_USER_ID

    tx = Transaction(
        id=tx_id,
        user_id=user_id,
        wallet_id=payload.wallet_id,
        category_id=payload.category_id,
        tipe=payload.tipe,
        total=payload.total,
        tanggal=payload.tanggal,
        nama_toko=payload.nama_toko,
        catatan=payload.catatan,
        foto_struk_path=payload.foto_struk_path,
        sumber=payload.sumber,
        confidence=payload.confidence,
        synced_at=datetime.utcnow(),
    )
    db.add(tx)

    for item in payload.items:
        tx_item = TransactionItem(
            id=item.id or uuid.uuid4(),
            transaction_id=tx_id,
            nama_item=item.nama_item,
            qty=item.qty,
            harga_satuan=item.harga_satuan,
            subtotal=item.subtotal,
        )
        db.add(tx_item)

    db.commit()
    db.refresh(tx)
    return tx


@router.delete("/{tx_id}")
def delete_transaction(tx_id: uuid.UUID, db: Session = Depends(get_db)):
    tx = db.query(Transaction).filter(Transaction.id == tx_id).first()
    if not tx:
        raise HTTPException(status_code=404, detail="Transaksi tidak ditemukan")

    # Soft delete
    tx.deleted_at = datetime.utcnow()
    tx.updated_at = datetime.utcnow()
    db.commit()
    return {"message": "Transaksi berhasil dihapus (soft delete)", "id": str(tx_id)}

