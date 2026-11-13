Write-Host "Menjalankan StrukKu Backend API (FastAPI) dengan Python Global..." -ForegroundColor Cyan
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
