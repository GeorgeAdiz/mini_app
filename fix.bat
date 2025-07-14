@echo off
echo ========================================
echo    Mini App 1 - Auto Fix Script
echo ========================================
echo.

echo [1/6] Stopping existing processes...
taskkill /f /im node.exe 2>nul
taskkill /f /im mongod.exe 2>nul
echo ✓ Processes stopped

echo.
echo [2/6] Checking MongoDB installation...
mongod --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ MongoDB not found! Please install MongoDB Community Server
    echo Download from: https://www.mongodb.com/try/download/community
    pause
    exit /b 1
) else (
    echo ✓ MongoDB found
)

echo.
echo [3/6] Starting MongoDB...
start /B mongod
echo ✓ MongoDB started

echo.
echo [4/6] Waiting for MongoDB to initialize...
timeout /t 5 /nobreak >nul

echo.
echo [5/6] Starting server...
cd mini-app
start /B npm start
echo ✓ Server started

echo.
echo [6/6] Waiting for server to initialize...
timeout /t 3 /nobreak >nul

echo.
echo ========================================
echo    Testing Connection...
echo ========================================
echo.

echo Testing server connection...
curl -s http://192.168.194.4:3000/books >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Server is responding!
    echo.
    echo ========================================
    echo    Fix Complete! 🎉
    echo ========================================
    echo.
    echo Your server is now running at:
    echo http://192.168.194.4:3000
    echo.
    echo You can now run your Flutter app:
    echo flutter run
    echo.
) else (
    echo ❌ Server not responding
    echo.
    echo Please check:
    echo 1. MongoDB is running
    echo 2. No firewall blocking port 3000
    echo 3. IP address is correct
    echo.
)

echo Press any key to exit...
pause >nul 