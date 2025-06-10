const sequelize = require('../config/database');

async function createPet(req, res) {
  const { name, species, breed, age, personality, foodSource, favoritePark, leashSource, litterType, waterProducts } = req.body;
  try {
    const pet = await sequelize.query(
      `INSERT INTO pets (name, species, breed, age, personality, food_source, favorite_park, leash_source, litter_type, water_products, user_id)
       VALUES (:name, :species, :breed, :age, :personality, :foodSource, :favoritePark, :leashSource, :litterType, :waterProducts, :userId)
       RETURNING *`,
      {
        replacements: {
          name,
          species,
          breed,
          age,
          personality,
          foodSource,
          favoritePark,
          leashSource,
          litterType,
          waterProducts,
          userId: req.user.userId
        },
        type: sequelize.QueryTypes.INSERT
      }
    );
    res.status(201).json(pet[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

async function getPets(req, res) {
  try {
    const pets = await sequelize.query(
      'SELECT * FROM pets WHERE user_id = :userId',
      {
        replacements: { userId: req.user.userId },
        type: sequelize.QueryTypes.SELECT
      }
    );
    res.json(pets);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

module.exports = { createPet, getPets };