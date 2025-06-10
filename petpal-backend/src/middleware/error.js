const { logger } = require('../utils/logger');

function errorHandler(err, req, res, next) {
  logger.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!', error: err.message });
}

module.exports = { errorHandler };