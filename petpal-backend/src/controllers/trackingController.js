const sequelize = require('../config/database');

async function addTrackingMetric(req, res) {
  const { petId, name, value } = req.body;
  try {
    const metric = await sequelize.query(
      `INSERT INTO tracking_metrics (pet_id, name, value, timestamp)
       VALUES (:petId, :name, :value, CURRENT_TIMESTAMP)
       RETURNING *`,
      {
        replacements: { petId, name, value },
        type: sequelize.QueryTypes.INSERT
      }
    );
    res.status(201).json(metric[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

async function getTrackingMetrics(req, res) {
  const { petId } = req.query;
  try {
    const metrics = await sequelize.query(
      'SELECT * FROM tracking_metrics WHERE pet_id = :petId',
      {
        replacements: { petId },
        type: sequelize.QueryTypes.SELECT
      }
    );
    res.json(metrics);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

module.exports = { addTrackingMetric, getTrackingMetrics };