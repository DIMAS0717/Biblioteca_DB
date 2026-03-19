const express = require('express');
const router = express.Router();
const pool = require('../config/db');

router.get('/', async (req, res, next) => {
  try {
    const [rows] = await pool.query('SELECT * FROM Users');
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
    const { nombre, apellido, email, telefono } = req.body;

    await pool.query(
      'CALL sp_registrar_usuario(?, ?, ?, ?, @mensaje)',
      [nombre, apellido, email, telefono]
    );

    const [mensajeRows] = await pool.query('SELECT @mensaje AS mensaje');

    res.status(201).json({
      ok: true,
      message: mensajeRows[0].mensaje
    });
  } catch (error) {
    next(error);
  }
});

router.get('/:id/loans-count', async (req, res, next) => {
  try {
    const { id } = req.params;

    const [rows] = await pool.query(
      'SELECT fn_libros_prestados_usuario(?) AS total',
      [id]
    );

    res.json({
      ok: true,
      userId: Number(id),
      librosPrestados: rows[0].total
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;