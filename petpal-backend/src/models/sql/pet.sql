CREATE TABLE pets (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  species VARCHAR(255) NOT NULL,
  breed VARCHAR(255),
  age INT,
  personality TEXT,
  food_source VARCHAR(255),
  favorite_park VARCHAR(255),
  leash_source VARCHAR(255),
  litter_type VARCHAR(255),
  water_products VARCHAR(255),
  user_id INT REFERENCES users(id)
);