@echo off
REM Git Auto Sync Script
REM Bu script, yerel değişiklikleri commit eder ve uzak depoya gönderir.

REM Proje klasörüne git
cd /d C:\flutter\app\sea\seaofsea

REM Uzak depodan değişiklikleri al
echo.
echo ------------------------------------
echo      Uzak depo değişiklikleri alınıyor...
echo ------------------------------------
git pull origin main

REM Yerel değişiklikleri ekle ve commit et
echo.
echo ------------------------------------
echo      Değişiklikler commit ediliyor...
echo ------------------------------------
git add .
git commit -m "Auto-sync: %date% %time%"

REM Yerel değişiklikleri uzak depoya gönder
echo.
echo ------------------------------------
echo      Değişiklikler uzak depoya gönderiliyor...
echo ------------------------------------
git push origin main

REM İşlem tamamlandı mesajı
echo.
echo ------------------------------------
echo      Git Sync İşlemi Tamamlandı!
echo ------------------------------------
