from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routers import parse, transactions, categories
from app.database import engine, Base

# Inisialisasi tabel jika belum ada
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="StrukKu Backend API",
    description="Backend API untuk aplikasi StrukKu: Parser Struk AI & PostgreSQL Storage",
    version="1.0.0",
)

# Izinkan CORS agar Flutter Mobile / Web / Emulator bisa akses
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Daftarkan Router
app.include_router(parse.router)
app.include_router(transactions.router)
app.include_router(categories.router)


@app.get("/api/health", tags=["Sistem"])
def health_check():
    return {
        "status": "ok",
        "service": "StrukKu Backend API",
        "version": "1.0.0",
        "database": f"{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}",
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.SERVER_HOST,
        port=settings.SERVER_PORT,
        reload=True,
    )

