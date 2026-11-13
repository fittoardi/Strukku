from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Category, Wallet
from app.schemas import CategoryResponse, WalletResponse

router = APIRouter(prefix="/api", tags=["Kategori & Dompet"])


@router.get("/categories", response_model=List[CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    return db.query(Category).filter(Category.deleted_at.is_(None)).order_by(Category.nama.asc()).all()


@router.get("/wallets", response_model=List[WalletResponse])
def get_wallets(db: Session = Depends(get_db)):
    return db.query(Wallet).filter(Wallet.deleted_at.is_(None)).order_by(Wallet.nama.asc()).all()

