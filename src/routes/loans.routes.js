const express = require('express');
const router = express.Router();
const pool = require('../config/db');

router.get('/', async (req, res, next) => {
  try {
    const [rows] = await pool.query(`
      SELECT l.*, 
             u.nombre, u.apellido,
             b.titulo
      FROM Loans l
      INNER JOIN Users u ON l.userId = u.userId
      INNER JOIN Books b ON l.bookId = b.bookId
      ORDER BY l.loanId DESC
    `);

    res.json({
      ok: true,
      data: rows
    });
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const { userId, bookId, diasPrestamo } = req.body;

    await pool.query(
      'CALL sp_realizar_prestamo(?, ?, ?, @mensaje)',
      [userId, bookId, diasPrestamo]
    );

    const [mensajeRows] = await pool.query('SELECT @mensaje AS mensaje');

    const mensaje = mensajeRows[0].mensaje;
    const status = mensaje.startsWith('Error') ? 400 : 201;

    res.status(status).json({
      ok: !mensaje.startsWith('Error'),
      message: mensaje
    });
  } catch (error) {
    next(error);
  }
});

router.put('/:id/return', async (req, res, next) => {
  try {
    const { id } = req.params;

    await pool.query(
      'CALL sp_registrar_devolucion(?, @mensaje)',
      [id]
    );

    const [mensajeRows] = await pool.query('SELECT @mensaje AS mensaje');

    const mensaje = mensajeRows[0].mensaje;
    const status = mensaje.startsWith('Error') ? 400 : 200;

    res.status(status).json({
      ok: !mensaje.startsWith('Error'),
      message: mensaje
    });
  } catch (error) {
    next(error);
  }
});

router.get('/active/total', async (req, res, next) => {
  try {
    const [rows] = await pool.query(
      'SELECT fn_total_prestamos_activos() AS total'
    );

    res.json({
      ok: true,
      prestamosActivos: rows[0].total
    });
  } catch (error) {
    next(error);
  }
});

router.get('/book/:id/available', async (req, res, next) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.query(
      'SELECT fn_libro_disponible(?) AS disponible',
      [id]
    );

    res.json({
      ok: true,
      bookId: Number(id),
      disponible: rows[0].disponible === 1
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;