const express = require('express');
const router = express.Router();
const {buscarMascotas} = require('../controllers/mascotasController'); 

// Get /mascotas/buscar
router.get ('/buscar', buscarMascotas);

module.exports = router