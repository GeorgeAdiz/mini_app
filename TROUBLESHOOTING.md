# 🔧 Troubleshooting Guide - Mini App 1

## 🚨 Common Issues and Solutions

### 1. "Could not connect to server" Error

**Symptoms:**
- Flutter app shows "Could not connect to server"
- Console shows "Connection refused" errors

**Solutions:**

#### A. Check if Server is Running
```bash
# Navigate to mini-app directory
cd mini-app

# Start the server
npm start

# You should see:
# ✅ Server running at http://192.168.194.4:3000
# ✅ MongoDB connected successfully
```

#### B. Check MongoDB Installation
```bash
# Check if MongoDB is installed
mongod --version

# If not installed, download from:
# https://www.mongodb.com/try/download/community
```

#### C. Check IP Address
```bash
# Get your current IP address
ipconfig

# Update the IP in these files:
# - lib/add_book_page.dart
# - lib/home_page.dart
# - mini-app/index.js
```

### 2. MongoDB Connection Error

**Symptoms:**
- Server shows "❌ MongoDB connection error"
- Database operations fail

**Solutions:**

#### A. Install MongoDB Community Server
1. Download from: https://www.mongodb.com/try/download/community
2. Install with default settings
3. MongoDB should start as a Windows service

#### B. Use MongoDB Atlas (Alternative)
1. Go to: https://www.mongodb.com/atlas
2. Create free account
3. Get connection string
4. Update `mini-app/index.js` with your connection string

### 3. Flutter App Issues

**Symptoms:**
- App crashes on startup
- UI doesn't load properly
- Network requests fail

**Solutions:**

#### A. Update Dependencies
```bash
# In the root directory
flutter pub get
flutter clean
flutter pub get
```

#### B. Check Network Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 4. Image Upload Issues

**Symptoms:**
- Images don't upload
- Image URLs are broken
- Server can't find uploaded files

**Solutions:**

#### A. Check Uploads Directory
```bash
# Make sure uploads directory exists
cd mini-app
mkdir uploads
```

#### B. Check File Permissions
Make sure the server has write permissions to the uploads directory.

### 5. Port Already in Use

**Symptoms:**
- Server won't start
- "Port 3000 is already in use" error

**Solutions:**

#### A. Kill Existing Process
```bash
# Find process using port 3000
netstat -ano | findstr :3000

# Kill the process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

#### B. Use Different Port
Update `mini-app/index.js`:
```javascript
const PORT = 3001; // Change to different port
```

## 🔍 Debugging Steps

### 1. Server Debugging
```bash
# Start server with verbose logging
cd mini-app
node index.js

# Check console output for:
# - MongoDB connection status
# - Server startup messages
# - Request/response logs
```

### 2. Flutter Debugging
```bash
# Run Flutter app with verbose logging
flutter run --verbose

# Check console for:
# - Network request logs
# - Error messages
# - Connection attempts
```

### 3. Network Testing
```bash
# Test server connectivity
curl http://192.168.194.4:3000/books

# Test from browser
# Open: http://192.168.194.4:3000/books
```

## 📋 Quick Fix Checklist

- [ ] MongoDB is installed and running
- [ ] Server is running (`npm start` in mini-app directory)
- [ ] IP address is correct in all files
- [ ] Firewall allows connections on port 3000
- [ ] Flutter dependencies are up to date
- [ ] Network permissions are set in Android manifest
- [ ] Uploads directory exists and has write permissions

## 🆘 Emergency Fix

If nothing works, try this complete reset:

1. **Stop all processes**
2. **Restart MongoDB service**
3. **Clear Flutter cache**: `flutter clean && flutter pub get`
4. **Restart server**: `cd mini-app && npm start`
5. **Test connection**: Open http://192.168.194.4:3000/books in browser
6. **Run Flutter app**: `flutter run`

## 📞 Getting Help

If you're still having issues:

1. **Check the console output** for specific error messages
2. **Verify all services are running** (MongoDB, Node.js server)
3. **Test network connectivity** between Flutter app and server
4. **Check Windows Firewall** settings
5. **Ensure all dependencies are installed** correctly

## 🔄 Auto-Fix Script

Create a file called `fix.bat` in your project root:

```batch
@echo off
echo Fixing Mini App 1...

echo Stopping existing processes...
taskkill /f /im node.exe 2>nul
taskkill /f /im mongod.exe 2>nul

echo Starting MongoDB...
start /B mongod

echo Waiting for MongoDB...
timeout /t 5 /nobreak

echo Starting server...
cd mini-app
start /B npm start

echo Waiting for server...
timeout /t 3 /nobreak

echo Testing connection...
curl http://192.168.194.4:3000/books

echo Fix complete! Try running your Flutter app now.
pause
```

Run this script to automatically fix common issues. 