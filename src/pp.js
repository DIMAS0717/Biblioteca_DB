const express = require('express');
const booksRoutes = require('./routes/books.routes');
const usersRoutes = require('./routes/users.routes');
const loansRoutes = require('./routes/loans.routes');

const app = express();

app.use(express.json());

app.use('/books', booksRoutes);
app.use('/users', usersRoutes);
app.use('/loans', loansRoutes);

app.use((err, req, res, next) => {
  console.error(err);

  return res.status(500).json({
    ok: false,
    message: 'Error interno del servidor',
    error: err.message
  });
});

module.exports = app;