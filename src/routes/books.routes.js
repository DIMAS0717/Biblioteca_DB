const express = require('express');
const router = express.Router();
const pool = require('../config/db');

router.get('/', async (req, res, next) => {
  try {
    const [rows] = await pool.query('SELECT * FROM Books');
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
    const {
      titulo,
      autor,
      isbn,
      anioPublicacion,
      categoria,
      totalEjemplares
    } = req.body;

    const sql = `
      CALL sp_registrar_libro(?, ?, ?, ?, ?, ?, @mensaje);
    `;

    await pool.query(sql, [
      titulo,
      autor,
      isbn,
      anioPublicacion,
      categoria,
      totalEjemplares
    ]);

    const [mensajeRows] = await pool.query('SELECT @mensaje AS mensaje');

    res.status(201).json({
      ok: true,
      message: mensajeRows[0].mensaje
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;