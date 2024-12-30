@echo off
echo Değişiklikler ekleniyor...
git add .

echo Commit mesajını yazın:
set /p commitMessage="Commit Mesajı: "

echo Commit işlemi yapılıyor...
git commit -m "%commitMessage%"

echo Değişiklikler gönderiliyor (push)...
git push

echo İşlem tamamlandı!
pause
