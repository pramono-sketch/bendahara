cd C:\project_flutter\bendahara\
cd C:\project_flutter\bendahara\lib\

$dst='C:\Users\Hype AMD\Archives\dart convert to text\lib'; if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }; New-Item -ItemType Directory -Force $dst | Out-Null; Get-ChildItem -Recurse -Filter *.dart | ForEach-Object { $rel=$_.FullName.Substring((Get-Location).Path.Length); $out=Join-Path $dst ($rel -replace '\.dart$','.txt'); New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null; Copy-Item $_.FullName $out -Force }

tree /F /A > "C:\Users\Hype AMD\Archives\Structure three\struktur_bendahara.txt"
notepad "C:\Users\Hype AMD\Archives\Structure three\struktur_bendahara.txt"

$dst="C:\Users\Hype AMD\Archives\dart convert to text\kode_bendahara.txt"; if(Test-Path $dst){Remove-Item $dst -Force}; Get-ChildItem -Recurse -Filter *.dart | ForEach-Object {Add-Content $dst "=================================================="; Add-Content $dst "FILE: $($_.FullName)"; Add-Content $dst "=================================================="; Get-Content $_.FullName | Add-Content $dst; Add-Content $dst ""}

1. Card konsisten
2. Responsiveness:buat handling untuk layar kecil
3. Loading state:indikator loading saat proses
4. Error handling
5. tema:neomorphism

5. Global variables
6. Separation of concerns

1. ekstensi color picker: ColorZilla
2. mendalami github(hubungkan github ke chatgpt dan sebagainya)

1. keperluan pengajar
2. keperluan bulanan:listrik,galon,pajak bumi bangunan,lab,ac,pc,meja(elektronik),atk(alat tulis dan keperluan),kegiatan

1. buat notifikasi akhir bulan yang digunakan untuk mengingatkan gaji guru

1. integrasikan dengan firebase
2. design
3. multi language
4. AI integrate

dashboard
1. ai interaktif
2. statistik

<!-- Database akun digital: tambah/edit/hapus akun, filter kelas, pencarian, kenaikan kelas, arsip akun lulus, tab guru/siswa. -->

gaji guru:
1. Testing mulai dari Popup Management Guru
2. Testing Riwayat Guru yang kompleks dan rapi
3. Testing fitur Arsip
4. Testing Folder Arsip
5. Testing Arsip Excel per tahun
6. Testing Arsip Excel per bulan
7. Membuat template

1.aku berikan contoh setting.dart sebagai pages yang sudah aku include ui dan kuperbarui tampilanya untuk referensi anda.

                            PR
1. memperbaiki apperaence ai pages
2. tema di bottom navigation

