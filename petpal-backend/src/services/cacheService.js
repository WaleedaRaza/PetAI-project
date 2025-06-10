const cache = new Map();

function get(key) {
  const data = cache.get(key);
  if (data && data.expiry > Date.now()) {
    return data.value;
  }
  cache.delete(key);
  return null;
}

function set(key, value, ttl = 300) {
  cache.set(key, { value, expiry: Date.now() + ttl * 1000 });
}

function deleteKey(key) {
  cache.delete(key);
}

function clearExpired() {
  const now = Date.now();
  for (const [key, data] of cache) {
    if (data.expiry < now) {
      cache.delete(key);
    }
  }
}

module.exports = { get, set, deleteKey, clearExpired };