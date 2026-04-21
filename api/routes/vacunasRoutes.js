const express = require('express');
const router = express.Router();
const { getVacunasPendientes, aplicarVacuna } = require ('../controllers/vacunasController');

router.get('/pendientes', getVacunasPendientes);
router.post('/aplicar', aplicarVacuna);

module.exports = router;
