-- ==============================================================
-- StrukKu: Database Schema & Initial Data (PostgreSQL)
-- ==============================================================

-- 1. Enable extension untuk UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Buat Tabel Users
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nama TEXT NOT NULL,
    mata_uang TEXT NOT NULL DEFAULT 'IDR',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Buat Tabel Wallets (Dompet / Akun Bank / Tunai)
CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    nama TEXT NOT NULL,
    tipe TEXT NOT NULL DEFAULT 'tunai',
    saldo_awal BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

-- 4. Buat Tabel Categories (Kategori Pengeluaran & Pemasukan)
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    nama TEXT NOT NULL,
    ikon TEXT NOT NULL DEFAULT 'category',
    warna TEXT NOT NULL DEFAULT 'FF009688',
    tipe TEXT NOT NULL DEFAULT 'keluar', -- 'masuk' | 'keluar'
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

-- 5. Buat Tabel Transactions (Transaksi Utama)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    tipe TEXT NOT NULL CHECK (tipe IN ('masuk', 'keluar')),
    total BIGINT NOT NULL CHECK (total >= 0),
    tanggal DATE NOT NULL,
    nama_toko TEXT,
    catatan TEXT,
    foto_struk_path TEXT,
    sumber TEXT NOT NULL DEFAULT 'manual' CHECK (sumber IN ('scan', 'manual')),
    confidence REAL CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 1)),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    synced_at TIMESTAMPTZ
);

-- 6. Buat Tabel Transaction Items (Rincian Produk per Struk)
CREATE TABLE IF NOT EXISTS transaction_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    nama_item TEXT NOT NULL,
    qty INTEGER NOT NULL DEFAULT 1 CHECK (qty > 0),
    harga_satuan BIGINT NOT NULL DEFAULT 0,
    subtotal BIGINT NOT NULL DEFAULT 0
);

-- 7. Buat Tabel Budgets (Target Anggaran Bulanan)
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    bulan TEXT NOT NULL, -- Format: 'YYYY-MM'
    batas BIGINT NOT NULL CHECK (batas >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_user_category_bulan UNIQUE (user_id, category_id, bulan)
);

-- 8. Buat Tabel Merchant Rules (Auto-kategori berdasarkan riwayat koreksi toko)
CREATE TABLE IF NOT EXISTS merchant_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    nama_toko_normalized TEXT NOT NULL,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_merchant UNIQUE (user_id, nama_toko_normalized)
);

-- 9. Indexes untuk Performa Query
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, tanggal);
CREATE INDEX IF NOT EXISTS idx_transactions_deleted ON transactions(deleted_at);
CREATE INDEX IF NOT EXISTS idx_items_transaction_id ON transaction_items(transaction_id);
CREATE INDEX IF NOT EXISTS idx_budgets_user_bulan ON budgets(user_id, bulan);

-- ==============================================================
-- SEED DATA DEFAULT (User awal, Dompet awal, & Kategori Standar)
-- ==============================================================

-- Masukkan user lokal default jika belum ada
INSERT INTO users (id, nama, mata_uang)
VALUES ('00000000-0000-0000-0000-000000000001', 'Pengguna Lokal', 'IDR')
ON CONFLICT (id) DO NOTHING;

-- Dompet default "Tunai"
INSERT INTO wallets (id, user_id, nama, tipe, saldo_awal)
VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Tunai', 'tunai', 0)
ON CONFLICT (id) DO NOTHING;

-- Kategori Default Pengeluaran & Pemasukan
INSERT INTO categories (user_id, nama, ikon, warna, tipe, is_default)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'Makanan', 'restaurant', 'FFE57373', 'keluar', true),
    ('00000000-0000-0000-0000-000000000001', 'Transportasi', 'directions_car', 'FF64B5F6', 'keluar', true),
    ('00000000-0000-0000-0000-000000000001', 'Belanja', 'shopping_cart', 'FFFFA726', 'keluar', true),
    ('00000000-0000-0000-0000-000000000001', 'Tagihan', 'receipt_long', 'FFBA68C8', 'keluar', true),
    ('00000000-0000-0000-0000-000000000001', 'Kesehatan', 'medical_services', 'FF4DB6AC', 'keluar', true),
    ('00000000-0000-0000-0000-000000000001', 'Hiburan', 'sports_esports', 'FF81C784', 'keluar', true),
    ('00000000-0000-0000-0000-000000000001', 'Pendidikan', 'school', 'FF9575CD', 'keluar', true),
    ('00000000-0000-0000-0000-000000000001', 'Lainnya', 'more_horiz', 'FF90A4AE', 'keluar', true),
    ('00000000-0000-0000-0000-000000000001', 'Gaji', 'payments', 'FF81C784', 'masuk', true),
    ('00000000-0000-0000-0000-000000000001', 'Pemasukan Lain', 'account_balance_wallet', 'FF4DB6AC', 'masuk', true)
ON CONFLICT DO NOTHING;

