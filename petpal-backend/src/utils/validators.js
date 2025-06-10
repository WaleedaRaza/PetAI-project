const Joi = require('joi');

function validatePet(pet) {
  const schema = Joi.object({
    name: Joi.string().required(),
    species: Joi.string().required(),
    breed: Joi.string().allow(''),
    age: Joi.number().integer().min(0).allow(null),
    personality: Joi.string().allow(''),
    foodSource: Joi.string().allow(''),
    favoritePark: Joi.string().allow(''),
    leashSource: Joi.string().allow(''),
    litterType: Joi.string().allow(''),
    waterProducts: Joi.string().allow('')
  });
  return schema.validate(pet);
}

function validateUser(user) {
  const schema = Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required()
  });
  return schema.validate(user);
}

module.exports = { validatePet, validateUser };