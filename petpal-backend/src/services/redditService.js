const axios = require('axios');
const { get, set } = require('./cacheService');
async function fetchRedditPosts(subreddit) {
  const cacheKey = `reddit:${subreddit}`;
  const cached = get(cacheKey);
  if (cached) return cached;

  try {
    const url = `https://www.reddit.com/r/${subreddit}.json`;
    const response = await axios.get(url, {
      headers: { 'User-Agent': 'PetPalBackend/1.0' }
    });
    const posts = response.data.data.children.map(child => ({
      title: child.data.title || '',
      selftext: child.data.selftext || '',
      created_utc: child.data.created_utc || Math.floor(Date.now() / 1000),
      author: child.data.author || 'Unknown',
      subreddit: child.data.subreddit || subreddit,
      hasImage: child.data.url ? (child.data.url.endsWith('.jpg') || child.data.url.endsWith('.png') || child.data.url.endsWith('.gif')) : false,
      source: 'Reddit'
    }));
    set(cacheKey, posts, 300); // Cache for 5 minutes
    return posts;
  } catch (error) {
    throw new Error(`Failed to fetch Reddit posts: ${error.message}`);
  }
}