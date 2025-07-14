# 🚀 Setup Guide - Fix Database Connection Issues

## ❌ Current Problem
You can't post data to the database because MongoDB is not installed on your system.

## ✅ Solutions (Choose One)

### Option 1: Install MongoDB Community Server (Recommended for Development)

1. **Download MongoDB Community Server**
   - Go to: https://www.mongodb.com/try/download/community
   - Download the Windows version
   - Install with default settings

2. **Start MongoDB Service**
   ```bash
   # MongoDB should start automatically as a Windows service
   # To check if it's running, open Services (services.msc)
   # Look for "MongoDB" service and make sure it's running
   ```

3. **Start Your Server**
   ```bash
   cd mini-app
   npm start
   ```

### Option 2: Use MongoDB Atlas (Cloud Database - Easier Setup)

1. **Create Free MongoDB Atlas Account**
   - Go to: https://www.mongodb.com/atlas
   - Sign up for a free account
   - Create a new cluster (free tier)

2. **Get Connection String**
   - Click "Connect" on your cluster
   - Choose "Connect your application"
   - Copy the connection string

3. **Update Your Server Code**
   - Open `mini-app/index.js`
   - Replace the MongoDB connection with your Atlas connection string:
   ```javascript
   const MONGODB_URI = 'mongodb+srv://your_username:your_password@your_cluster.mongodb.net/booksdb?retryWrites=true&w=majority';
   
   mongoose.connect(MONGODB_URI, {
     useNewUrlParser: true,
     useUnifiedTopology: true,
   })
   ```

4. **Start Your Server**
   ```bash
   cd mini-app
   npm start
   ```

## 🔧 Testing Your Setup

1. **Check Server Status**
   - Open browser and go to: http://localhost:3000/books
   - You should see an empty array `[]` or your books data

2. **Test from Flutter App**
   - Run your Flutter app
   - Try to add a book
   - Check the console for detailed error messages

## 🐛 Troubleshooting

### If you get "Could not connect to server":
1. Make sure the server is running (`npm start` in mini-app folder)
2. Check if MongoDB is running
3. Verify the IP address in your Flutter app matches your computer's IP
4. Check Windows Firewall settings

### If you get "MongoDB connection error":
1. MongoDB is not installed or not running
2. Follow the installation steps above

### To find your computer's IP address:
```bash
# In Command Prompt or PowerShell
ipconfig
# Look for "IPv4 Address" under your network adapter
```

## 📱 Flutter App Configuration

The Flutter app tries these URLs in order:
- `http://192.168.193.252:3000/books` (Your current IP)
- `http://10.0.2.2:3000/books` (Android emulator)
- `http://localhost:3000/books` (Local development)
- `http://127.0.0.1:3000/books` (Local development)

If your IP address changes, update the first URL in `lib/add_book_page.dart` and `lib/home_page.dart`.

## 🎯 Quick Fix Steps

1. **Install MongoDB Community Server** (Option 1 above)
2. **Start the server**: `cd mini-app && npm start`
3. **Test**: Open http://localhost:3000/books in browser
4. **Run Flutter app** and try adding a book

## 📞 Need Help?

If you're still having issues:
1. Check the console output for error messages
2. Make sure all services are running
3. Verify network connectivity
4. Check firewall settings 