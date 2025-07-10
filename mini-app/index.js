const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const PORT = 3000;

app.use(express.json());
app.use(cors());

//Connect to MongoDB with database name
mongoose.connect('mongodb://localhost:27017/booksdb', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => console.log('MongoDB connected'))
  .catch(err => console.error('MongoDB connection error:', err));

//Define schema and model
const bookSchema = new mongoose.Schema({
  title: String,
  author: String
});

const Book = mongoose.model('Book', bookSchema);

//Get all books
app.get('/books', async (req, res) => {
  const books = await Book.find();
  res.json(books);
});

//Post a new book
app.post('/books', async (req, res) => {
  const newBook = new Book(req.body);
  await newBook.save();
  res.status(201).json(newBook);
});

//Delete a book by ID
app.delete('/books/:id', async (req, res) => {
  try {
    const deletedBook = await Book.findByIdAndDelete(req.params.id);
    if (!deletedBook) {
      return res.status(404).json({ message: 'Book not found' });
    }
    res.json({ message: 'Book deleted', book: deletedBook });
  } catch (err) {
    res.status(500).json({ message: 'Error deleting book', error: err });
  }
});

//Start the server
app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
