@echo off
echo Menjalankan StrukKu Backend API (FastAPI) dengan Python Global...
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
