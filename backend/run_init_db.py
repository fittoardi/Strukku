"""
Script otomatis untuk membuat database 'strukku' dan mengeksekusi skema tabel + seed data di PostgreSQL.
"""
import os
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from app.config import settings


def init_database():
    print(f"[*] Menghubungkan ke PostgreSQL ({settings.DB_HOST}:{settings.DB_PORT}) sebagai user '{settings.DB_USER}'...")

    # 1. Konek ke database bawaan 'postgres' untuk mengecek/membuat database 'strukku'
    try:
        conn = psycopg2.connect(
            host=settings.DB_HOST,
            port=settings.DB_PORT,
            user=settings.DB_USER,
            password=settings.DB_PASSWORD,
            dbname="postgres",
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()

        # Cek apakah database sudah ada
        cursor.execute("SELECT 1 FROM pg_database WHERE datname = %s", (settings.DB_NAME,))
        exists = cursor.fetchone()
        if not exists:
            print(f"[+] Membuat database '{settings.DB_NAME}'...")
            cursor.execute(f'CREATE DATABASE "{settings.DB_NAME}"')
            print(f"[✓] Database '{settings.DB_NAME}' berhasil dibuat.")
        else:
            print(f"[i] Database '{settings.DB_NAME}' sudah ada.")

        cursor.close()
        conn.close()

    except Exception as e:
        print(f"[!] Gagal menghubungkan ke PostgreSQL default: {e}")
        print("[!] Pastikan service PostgreSQL aktif dan password di backend/.env sudah sesuai.")
        return False

    # 2. Konek langsung ke database 'strukku' untuk menjalankan init_db.sql
    try:
        print(f"[*] Menjalankan skrip skema 'init_db.sql' pada database '{settings.DB_NAME}'...")
        conn = psycopg2.connect(
            host=settings.DB_HOST,
            port=settings.DB_PORT,
            user=settings.DB_USER,
            password=settings.DB_PASSWORD,
            dbname=settings.DB_NAME,
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()

        sql_path = os.path.join(os.path.dirname(__file__), "init_db.sql")
        with open(sql_path, "r", encoding="utf-8") as f:
            sql_script = f.read()

        cursor.execute(sql_script)
        print("[✓] Skema tabel dan seed data awal berhasil diterapkan!")

        # Verifikasi tabel
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name;
        """)
        tables = [row[0] for row in cursor.fetchall()]
        print(f"[✓] Tabel yang aktif ({len(tables)} tabel): {', '.join(tables)}")

        cursor.close()
        conn.close()
        return True

    except Exception as e:
        print(f"[!] Gagal menjalankan init_db.sql: {e}")
        return False


if __name__ == "__main__":
    success = init_database()
    if success:
        print("\n🎉 Setup Database PostgreSQL Selesai!")
    else:
        print("\n❌ Setup Database Gagal. Silakan periksa kembali konfigurasi database Anda.")

