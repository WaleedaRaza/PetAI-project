# Petpal.ai Backend

Backend for Petpal.ai, handling authentication, pet profiles, forum, and AI insights.

## Setup
1. Install Node.js and npm.
2. Run `npm install`.
3. Set up `.env` with API keys and DB credentials.
4. Run `docker-compose up -d` for databases.
5. Start server: `npm start`.

## Structure
- `src/config/`: Database and API configs
- `src/controllers/`: Request handlers
- `src/models/`: Database schemas
- `src/routes/`: API endpoints
- `src/services/`: External integrations
- `src/utils/`: Helpers
