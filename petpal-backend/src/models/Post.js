const mongoose = require("mongoose");

const postSchema = new mongoose.Schema({
  userId: String,
  content: String,
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Post", postSchema);