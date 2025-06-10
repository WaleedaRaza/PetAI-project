async function askAI(req, res) {
  const { prompt } = req.body;
  try {
    // Placeholder for OpenAI integration
    res.json({ response: `AI response to: ${prompt}` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

module.exports = { askAI };