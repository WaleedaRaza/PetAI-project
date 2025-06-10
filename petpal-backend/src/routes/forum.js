const express = require('express');
const router = express.Router();
const { getRedditPosts } = require('../controllers/forumController');

router.get('/reddit/posts', getRedditPosts);

module.exports = router;