const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// MongoDB Atlas connection (replace with your own connection string)
// You can get a free MongoDB Atlas account at: https://www.mongodb.com/atlas
const MONGODB_URI = 'mongodb+srv://your_username:your_password@your_cluster.mongodb.net/booksdb?retryWrites=true&w=majority';

// For now, let's use a local MongoDB connection with better error handling
mongoose.connect('mongodb://localhost:27017/booksdb', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => {
  console.log('✅ MongoDB connected successfully');
}).catch(err => {
  console.error('❌ MongoDB connection error:', err);
  console.log('💡 To fix this:');
  console.log('   1. Install MongoDB Community Server from: https://www.mongodb.com/try/download/community');
  console.log('   2. Or use MongoDB Atlas (cloud): https://www.mongodb.com/atlas');
  console.log('   3. Update the MONGODB_URI in this file with your connection string');
});

// Multer config
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadPath = 'uploads/';
    if (!fs.existsSync(uploadPath)) fs.mkdirSync(uploadPath);
    cb(null, uploadPath);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    cb(null, Date.now() + ext);
  },
});
const upload = multer({ storage });

// Mongo schema
const bookSchema = new mongoose.Schema({
  title: String,
  author: String,
  year: Number,
  category: String,
  imageUrl: String,
});
const Book = mongoose.model('Book', bookSchema);

// Endpoints
app.get('/books', async (req, res) => {
  const books = await Book.find();
  res.json(books);
});

app.post('/books', upload.single('image'), async (req, res) => {
  try {
    const { title, author, year, category } = req.body;
    const imageUrl = req.file ? `http://192.168.194.4:3000/uploads/${req.file.filename}` : '';

    const newBook = new Book({ title, author, year, category, imageUrl });
    await newBook.save();
    res.status(201).json(newBook);
  } catch (err) {
    res.status(400).json({ error: 'Failed to create book', details: err });
  }
});

app.put('/books/:id', upload.single('image'), async (req, res) => {
  try {
    const { title, author, year, category } = req.body;
    let updateData = { title, author, year, category };
    if (req.file) {
      updateData.imageUrl = `http://192.168.194.4:3000/uploads/${req.file.filename}`;
    }
    const updatedBook = await Book.findByIdAndUpdate(
      req.params.id,
      { $set: updateData },
      { new: true }
    );
    if (!updatedBook) return res.status(404).json({ message: 'Book not found' });
    res.json(updatedBook);
  } catch (err) {
    res.status(400).json({ error: 'Failed to update book', details: err });
  }
});

app.delete('/books/:id', async (req, res) => {
  const deletedBook = await Book.findByIdAndDelete(req.params.id);
  if (!deletedBook) return res.status(404).json({ message: 'Book not found' });
  res.json({ message: 'Book deleted', book: deletedBook });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server running at http://192.168.194.4:${PORT}`);
  console.log(`🌐 Server accessible from any network interface`);
});
