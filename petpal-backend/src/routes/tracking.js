const express = require('express');
const router = express.Router();
const { addTrackingMetric, getTrackingMetrics } = require('../controllers/trackingController');
const { authenticateToken } = require('../middleware/auth');

router.post('/', authenticateToken, addTrackingMetric);
router.get('/', authenticateToken, getTrackingMetrics);

module.exports = router;