#!/bin/bash
# Setup Aplikasi Absensi - App Absen
# Flutter + Supabase

echo "========================================"
echo "  SETUP APLIKASI ABSENSI"
echo "  Flutter + Supabase"
echo "========================================"
echo ""

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "[!] Flutter tidak ditemukan."
    echo "    Install Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "[✓] Flutter ditemukan: $(flutter --version | head -1)"

# Install dependencies
echo ""
echo "[*] Menginstall dependencies..."
flutter pub get

echo ""
echo "[*] Setup Supabase..."
echo ""
echo "========================================"
echo "  LANGKAH SETUP SUPABASE"
echo "========================================"
echo ""
echo "1. Buat project di https://supabase.com"
echo "2. Buka SQL Editor dan jalankan:"
echo "   supabase/migrations/00001_init.sql"
echo ""
echo "3. Copy file supabase_config.dart"
echo "   dan ganti 'your-project.supabase.co'"
echo "   dengan URL project Supabase Anda"
echo ""
echo "4. Ganti 'your-anon-key' dengan anon key"
echo "   dari project Supabase Anda"
echo ""
echo "========================================"
echo "  FITUR APLIKASI"
echo "========================================"
echo ""
echo "✓ Absensi GPS (radius 10m)"
echo "✓ Foto Selfie (kamera HP)"
echo "✓ Multi Shift Kerja"
echo "✓ Izin / Cuti"
echo "✓ Lembur (perhitungan otomatis)"
echo "✓ Payroll (Gaji + THR + BPJS)"
echo "✓ QR Code Signature"
echo "✓ Laporan Excel/PDF"
echo "✓ Push Notification"
echo "✓ Multi Role (Admin/Manager/Karyawan)"
echo ""
echo "========================================"
echo "  ROLE & LOGIN"
echo "========================================"
echo ""
echo "Role: admin, manager, karyawan"
echo ""
echo "Setelah setup database, insert admin:"
echo "1. Register via aplikasi"
echo "2. Atau insert manual di Supabase:"
echo "   INSERT INTO profiles (id, email, nama_lengkap, role)"
echo "   VALUES ('uuid', 'admin@email.com', 'Admin', 'admin');"
echo ""
echo "========================================"
echo ""
echo "Jalankan aplikasi:"
echo "  flutter run"
echo ""
