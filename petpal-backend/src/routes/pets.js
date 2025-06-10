const express = require('express');
const router = express.Router();
const { createPet, getPets } = require('../controllers/petController');
const { authenticateToken } = require('../middleware/auth');

router.post('/', authenticateToken, createPet);
router.get('/', authenticateToken, getPets);

module.exports = router;