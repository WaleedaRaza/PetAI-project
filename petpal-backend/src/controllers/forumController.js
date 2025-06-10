const { fetchRedditPosts } = require('../services/redditService');

async function getRedditPosts(req, res) {
  const subreddit = req.query.subreddit || 'pets';
  try {
    const rawPosts = await fetchRedditPosts(subreddit);
    const posts = rawPosts.map(post => ({
      title: post.title || '',
      selftext: post.selftext || '',
      created_utc: post.created_utc || Math.floor(Date.now() / 1000),
      author: post.author || 'Unknown',
      subreddit: post.subreddit || subreddit,
      hasImage: post.url ? (post.url.endsWith('.jpg') || post.url.endsWith('.png') || post.url.endsWith('.gif')) : false,
      source: 'Reddit'
    }));
    res.json(posts);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

module.exports = { getRedditPosts };