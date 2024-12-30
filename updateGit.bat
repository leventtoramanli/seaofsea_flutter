@echo off

:: Hedef dizine git
cd /d "C:\flutter\app\sea\seaofsea"

:: Değişiklikleri kontrol et
if exist "C:\flutter\app\sea\seaofsea" (
    echo Proje dizini bulundu.
) else (
    echo Proje dizini bulunamadı. Lütfen kontrol edin.
    pause
    exit /b
)

:: Git işlemleri
:: Değişiklikleri commit et
if exist .git (
    echo Git dizini bulundu, işlemler başlıyor...
    git add .
    git commit -m "Automatic update via batch file"
    git pull origin main
    git push origin main
) else (
    echo Git deposu bulunamadı. Lütfen dizini kontrol edin.
    pause
    exit /b
)

:: İşlem tamamlandı
echo Güncelleme işlemi tamamlandı.