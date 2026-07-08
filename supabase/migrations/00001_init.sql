-- ============================================
-- APLIKASI ABSENSI - Database Schema
-- Supabase PostgreSQL Migration
-- ============================================

-- 1. ENUM TYPES
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'karyawan');
CREATE TYPE attendance_status AS ENUM ('hadir', 'izin', 'cuti', 'alpha', 'telat');
CREATE TYPE leave_type AS ENUM ('izin', 'cuti_tahunan', 'cuti_hamil', 'cuti_sakit');
CREATE TYPE leave_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE shift_type AS ENUM ('pagi', 'siang', 'malam');
CREATE TYPE payroll_status AS ENUM ('draft', 'approved', 'paid');

-- 2. PROFILES (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  nama_lengkap TEXT NOT NULL,
  nip TEXT UNIQUE,
  no_telepon TEXT,
  alamat TEXT,
  foto_url TEXT,
  role user_role NOT NULL DEFAULT 'karyawan',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. POSITIONS / JABATAN
CREATE TABLE positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama_jabatan TEXT NOT NULL,
  gaji_pokok DECIMAL(15,2) NOT NULL,
  tunjangan_tetap DECIMAL(15,2) NOT NULL DEFAULT 0,
  uang_makan DECIMAL(15,2) NOT NULL DEFAULT 0,
  uang_transport DECIMAL(15,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE profiles ADD COLUMN position_id UUID REFERENCES positions(id);

-- 4. COMPANY CONFIG
CREATE TABLE company_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama_perusahaan TEXT NOT NULL DEFAULT 'PT. Contoh',
  alamat TEXT,
  logo_url TEXT,
  jam_masuk TIME NOT NULL DEFAULT '08:00',
  jam_keluar TIME NOT NULL DEFAULT '16:00',
  toleransi_terlambat INT NOT NULL DEFAULT 15, -- menit
  radius_gps INT NOT NULL DEFAULT 10, -- meter
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. SHIFTS
CREATE TABLE shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama_shift TEXT NOT NULL,
  tipe_shift shift_type NOT NULL DEFAULT 'pagi',
  jam_masuk TIME NOT NULL,
  jam_keluar TIME NOT NULL,
  tolerasi_terlambat INT NOT NULL DEFAULT 15,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. EMPLOYEE SHIFT ASSIGNMENT
CREATE TABLE employee_shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  shift_id UUID NOT NULL REFERENCES shifts(id) ON DELETE CASCADE,
  tanggal_assign DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(employee_id, tanggal_assign)
);

-- 7. GPS LOCATIONS (kantor)
CREATE TABLE gps_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama_lokasi TEXT NOT NULL,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  radius INT NOT NULL DEFAULT 10, -- meter
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. ATTENDANCES
CREATE TABLE attendances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  tanggal DATE NOT NULL,
  shift_id UUID REFERENCES shifts(id),
  jam_masuk TIMESTAMPTZ,
  jam_keluar TIMESTAMPTZ,
  foto_masuk_url TEXT,
  foto_keluar_url TEXT,
  latitude_masuk DECIMAL(10,8),
  longitude_masuk DECIMAL(11,8),
  latitude_keluar DECIMAL(10,8),
  longitude_keluar DECIMAL(11,8),
  status attendance_status NOT NULL DEFAULT 'hadir',
  qr_code_url TEXT,
  catatan TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(employee_id, tanggal)
);

-- 9. OVERTIME
CREATE TABLE overtimes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  tanggal DATE NOT NULL,
  jam_mulai TIMESTAMPTZ NOT NULL,
  jam_selesai TIMESTAMPTZ NOT NULL,
  total_jam DECIMAL(5,2) NOT NULL,
  keterangan TEXT,
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  is_approved BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. LEAVE REQUESTS
CREATE TABLE leave_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  tipe_izin leave_type NOT NULL DEFAULT 'izin',
  tanggal_mulai DATE NOT NULL,
  tanggal_selesai DATE NOT NULL,
  total_hari INT NOT NULL,
  alasan TEXT NOT NULL,
  status leave_status NOT NULL DEFAULT 'pending',
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  catatan_approval TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. BPJS CONFIG
CREATE TABLE bpjs_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama_bpjs TEXT NOT NULL,
  persentase_perusahaan DECIMAL(5,2) NOT NULL,
  persentase_karyawan DECIMAL(5,2) NOT NULL,
  maksimal_upah DECIMAL(15,2), -- maksimal upah yang dihitung
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO bpjs_config (nama_bpjs, persentase_perusahaan, persentase_karyawan, maksimal_upah) VALUES
  ('BPJS Kesehatan', 4.00, 1.00, 12000000),
  ('JKK (Kecelakaan Kerja)', 0.54, 0, 12000000),
  ('JKM (Kematian)', 0.30, 0, 12000000),
  ('JHT (Hari Tua)', 3.70, 2.00, 12000000),
  ('JP (Pensiun)', 2.00, 1.00, 12000000);

-- 12. THR CONFIG
CREATE TABLE thr_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tahun INT NOT NULL,
  persentase_penuh DECIMAL(5,2) NOT NULL DEFAULT 100.00, -- untuk >= 12 bulan
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 13. PAYROLL
CREATE TABLE payrolls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  periode_bulan INT NOT NULL, -- 1-12
  periode_tahun INT NOT NULL,
  gaji_pokok DECIMAL(15,2) NOT NULL DEFAULT 0,
  tunjangan_tetap DECIMAL(15,2) NOT NULL DEFAULT 0,
  uang_makan DECIMAL(15,2) NOT NULL DEFAULT 0,
  uang_transport DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_lembur DECIMAL(15,2) NOT NULL DEFAULT 0,
  thr DECIMAL(15,2) NOT NULL DEFAULT 0,
  bpjs_kesehatan_karyawan DECIMAL(15,2) NOT NULL DEFAULT 0,
  bpjs_jht_karyawan DECIMAL(15,2) NOT NULL DEFAULT 0,
  bpjs_jp_karyawan DECIMAL(15,2) NOT NULL DEFAULT 0,
  bpjs_jkk_perusahaan DECIMAL(15,2) NOT NULL DEFAULT 0,
  bpjs_jkm_perusahaan DECIMAL(15,2) NOT NULL DEFAULT 0,
  bpjs_jht_perusahaan DECIMAL(15,2) NOT NULL DEFAULT 0,
  bpjs_jp_perusahaan DECIMAL(15,2) NOT NULL DEFAULT 0,
  bpjs_kesehatan_perusahaan DECIMAL(15,2) NOT NULL DEFAULT 0,
  potongan_lain DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_pendapatan DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_potongan DECIMAL(15,2) NOT NULL DEFAULT 0,
  gaji_bersih DECIMAL(15,2) NOT NULL DEFAULT 0,
  status payroll_status NOT NULL DEFAULT 'draft',
  qr_code_url TEXT,
  approved_by UUID REFERENCES profiles(id),
  approved_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(employee_id, periode_bulan, periode_tahun)
);

-- 14. ATTENDANCE LOGS (untuk audit trail)
CREATE TABLE attendance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attendance_id UUID NOT NULL REFERENCES attendances(id) ON DELETE CASCADE,
  aksi TEXT NOT NULL, -- 'masuk' or 'keluar'
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  foto_url TEXT,
  device_info TEXT,
  ip_address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX idx_attendance_employee_date ON attendances(employee_id, tanggal);
CREATE INDEX idx_attendance_tanggal ON attendances(tanggal);
CREATE INDEX idx_overtime_employee ON overtimes(employee_id);
CREATE INDEX idx_leave_employee ON leave_requests(employee_id);
CREATE INDEX idx_payroll_employee_periode ON payrolls(employee_id, periode_bulan, periode_tahun);
CREATE INDEX idx_employee_shift_date ON employee_shifts(employee_id, tanggal_assign);

-- ============================================
-- ROW LEVEL SECURITY (Supabase)
-- ============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendances ENABLE ROW LEVEL SECURITY;
ALTER TABLE overtimes ENABLE ROW LEVEL SECURITY;
ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE payrolls ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE gps_locations ENABLE ROW LEVEL SECURITY;

-- Profiles: own profile + admin/manager see all
CREATE POLICY "Users view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admin view all profiles"
  ON profiles FOR SELECT
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

CREATE POLICY "Admin update profiles"
  ON profiles FOR UPDATE
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- Attendances: own + admin/manager
CREATE POLICY "Users view own attendance"
  ON attendances FOR SELECT
  USING (auth.uid() = employee_id);

CREATE POLICY "Admin view all attendance"
  ON attendances FOR SELECT
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role IN ('admin', 'manager')
    )
  );

CREATE POLICY "Users insert own attendance"
  ON attendances FOR INSERT
  WITH CHECK (auth.uid() = employee_id);

-- Payrolls: own view + admin full
CREATE POLICY "Users view own payroll"
  ON payrolls FOR SELECT
  USING (auth.uid() = employee_id);

CREATE POLICY "Admin manage payroll"
  ON payrolls FOR ALL
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_attendances_updated_at
  BEFORE UPDATE ON attendances FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_payrolls_updated_at
  BEFORE UPDATE ON payrolls FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Function: Calculate distance between two GPS points (Haversine)
CREATE OR REPLACE FUNCTION calculate_distance(
  lat1 DECIMAL, lon1 DECIMAL,
  lat2 DECIMAL, lon2 DECIMAL
) RETURNS DECIMAL AS $$
DECLARE
  R DECIMAL = 6371000; -- Earth radius in meters
  phi1 DECIMAL;
  phi2 DECIMAL;
  dphi DECIMAL;
  dlambda DECIMAL;
  a DECIMAL;
  c DECIMAL;
BEGIN
  phi1 := radians(lat1);
  phi2 := radians(lat2);
  dphi := radians(lat2 - lat1);
  dlambda := radians(lon2 - lon1);
  a := sin(dphi/2)^2 + cos(phi1) * cos(phi2) * sin(dlambda/2)^2;
  c := 2 * atan2(sqrt(a), sqrt(1-a));
  RETURN R * c;
END;
$$ LANGUAGE plpgsql;

-- Function: Check if employee is within GPS radius
CREATE OR REPLACE FUNCTION is_within_radius(
  emp_lat DECIMAL, emp_lon DECIMAL,
  office_lat DECIMAL, office_lon DECIMAL,
  radius_meters INT
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN calculate_distance(emp_lat, emp_lon, office_lat, office_lon) <= radius_meters;
END;
$$ LANGUAGE plpgsql;

-- Function: Calculate THR
CREATE OR REPLACE FUNCTION calculate_thr(
  p_employee_id UUID,
  p_tahun INT
) RETURNS DECIMAL AS $$
DECLARE
  v_gaji_pokok DECIMAL;
  v_tunjangan_tetap DECIMAL;
  v_tgl_masuk DATE;
  v_masa_kerja INT; -- in months
  v_thr DECIMAL;
BEGIN
  SELECT p.gaji_pokok, p.tunjangan_tetap
  INTO v_gaji_pokok, v_tunjangan_tetap
  FROM profiles pr
  JOIN positions p ON pr.position_id = p.id
  WHERE pr.id = p_employee_id;

  SELECT MIN(created_at)::DATE INTO v_tgl_masuk
  FROM attendances
  WHERE employee_id = p_employee_id;

  IF v_tgl_masuk IS NULL THEN
    RETURN 0;
  END IF;

  v_masa_kerja := EXTRACT(YEAR FROM age(
    make_date(p_tahun, 12, 31), v_tgl_masuk
  )) * 12 + EXTRACT(MONTH FROM age(
    make_date(p_tahun, 12, 31), v_tgl_masuk
  ));

  IF v_masa_kerja >= 12 THEN
    v_thr := v_gaji_pokok + v_tunjangan_tetap;
  ELSE
    v_thr := (v_gaji_pokok + v_tunjangan_tetap) * v_masa_kerja / 12;
  END IF;

  RETURN v_thr;
END;
$$ LANGUAGE plpgsql;
