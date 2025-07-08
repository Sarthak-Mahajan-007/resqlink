const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
app.use(cors());
app.use(bodyParser.json());

// TODO: Update these with your actual DB credentials
const pool = new Pool({
  user: 'your_db_user',
  host: 'localhost',
  database: 'your_db_name',
  password: 'your_db_password',
  port: 5432,
});

// Get profile by user ID
app.get('/profile/:userId', async (req, res) => {
  const { userId } = req.params;
  try {
    const profileRes = await pool.query('SELECT * FROM profile WHERE user_id = $1', [userId]);
    if (profileRes.rows.length === 0) return res.status(404).json({ error: 'Profile not found' });
    const profile = profileRes.rows[0];

    // Get health card
    let healthCard = null;
    if (profile.health_card_id) {
      const hcRes = await pool.query('SELECT * FROM health_card WHERE id = $1', [profile.health_card_id]);
      healthCard = hcRes.rows[0] || null;
    }
    profile.health_card = healthCard;
    res.json(profile);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create or update profile
app.post('/profile', async (req, res) => {
  const { user_id, bio, avatar_url, date_of_birth, gender, health_card } = req.body;
  try {
    // Upsert health card
    let healthCardId = null;
    if (health_card) {
      const hcRes = await pool.query(
        `INSERT INTO health_card (blood_group, allergies, medical_conditions, emergency_contact, created_at)
         VALUES ($1, $2, $3, $4, NOW())
         RETURNING id`,
        [
          health_card.blood_group,
          health_card.allergies,
          health_card.medical_conditions,
          health_card.emergency_contact,
        ]
      );
      healthCardId = hcRes.rows[0].id;
    }

    // Upsert profile
    const profileRes = await pool.query(
      `INSERT INTO profile (user_id, bio, avatar_url, date_of_birth, gender, health_card_id, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())
       ON CONFLICT (user_id) DO UPDATE SET
         bio = EXCLUDED.bio,
         avatar_url = EXCLUDED.avatar_url,
         date_of_birth = EXCLUDED.date_of_birth,
         gender = EXCLUDED.gender,
         health_card_id = EXCLUDED.health_card_id
       RETURNING *`,
      [user_id, bio, avatar_url, date_of_birth, gender, healthCardId]
    );
    res.json(profileRes.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create a new user with default profile and health card
app.post('/user', async (req, res) => {
  const { name, email } = req.body;
  try {
    // 1. Create user
    const userRes = await pool.query(
      `INSERT INTO users (name, email, created_at) VALUES ($1, $2, NOW()) RETURNING id`,
      [name, email]
    );
    const userId = userRes.rows[0].id;

    // 2. Create default health card
    const healthCardRes = await pool.query(
      `INSERT INTO health_card (blood_group, allergies, medical_conditions, emergency_contact, created_at)
       VALUES ('Unknown', 'None', 'None', '0000000000', NOW()) RETURNING id`,
    );
    const healthCardId = healthCardRes.rows[0].id;

    // 3. Create default profile
    await pool.query(
      `INSERT INTO profile (user_id, health_card_id, bio, avatar_url, date_of_birth, gender, created_at)
       VALUES ($1, $2, 'No bio yet', '', '2000-01-01', 'Other', NOW())`,
      [userId, healthCardId]
    );

    res.json({ user_id: userId, health_card_id: healthCardId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
}); 