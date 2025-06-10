const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth');
const petRoutes = require('./routes/pets');
const forumRoutes = require('./routes/forum');
const aiRoutes = require('./routes/ai');
const trackingRoutes = require('./routes/tracking');
const { logger } = require('./utils/logger');
const { errorHandler } = require('./middleware/error');
const { limiter } = require('./middleware/rateLimiter');

const app = express();

// Middleware
app.use(cors({ origin: 'http://localhost:8080' })); // Adjust for your frontend
app.use(express.json());
app.use(limiter);
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.url}`);
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/pets', petRoutes);
app.use('/api/forum', forumRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/tracking', trackingRoutes);

// Error handling
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`);
});

module.exports = app;