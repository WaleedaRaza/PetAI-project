const express = require('express');
const router = express.Router();
const { askAI } = require('../controllers/aiController');
const { authenticateToken } = require('../middleware/auth');

router.post('/ask', authenticateToken, askAI);

module.exports = router;