const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: 'root',
  database: 'checkIn',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

const JWT_SECRET = 'tQ+pYWCXmS94A8ZLrqHQ5uKQzWs5TVy8cOtEeJcSlrc=';

// Registration endpoint
app.post('/register', async (req, res) => {
    try {
      const { name, email, mobile, grade, password } = req.body;
      const hashedPassword = await bcrypt.hash(password, 10);
  
      console.log('Registering user:', { name, email, mobile, grade });
  
      const [result] = await pool.query(
        'INSERT INTO employees (name, email, mobile, grade, password) VALUES (?, ?, ?, ?, ?)',
        [name, email, mobile, grade, hashedPassword]
      );
  
      console.log('User registered:', result);
  
      res.status(201).json({ message: 'Employee registered successfully' });
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({ error: 'Registration failed' });
    }
  });

// Login endpoint
app.post('/login', async (req, res) => {
    try {
      const { email, password } = req.body;
  
      const [rows] = await pool.query('SELECT * FROM employees WHERE email = ?', [email]);
  
      if (rows.length === 0) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }
  
      const employee = rows[0];
      const passwordMatch = await bcrypt.compare(password, employee.password);
  
      if (!passwordMatch) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }
  
      const token = jwt.sign(
        { id: employee.id, grade: employee.grade },
        JWT_SECRET,
        { expiresIn: '1h' }
      );
  
      res.json({ token, grade: employee.grade });
    } catch (error) {
      res.status(500).json({ error: 'Login failed' });
    }
  });

// Check-in request endpoint
app.post('/checkin-request', authenticateToken, async (req, res) => {
    try {
      const { locationId } = req.body;
      const employeeGrade = req.user.grade;
  
      console.log(`Check-in request: Location ID: ${locationId}, Employee Grade: ${employeeGrade}`);
  
      const [permissions] = await pool.query(
        'SELECT allowed_grades FROM location_permissions WHERE location_id = ?',
        [locationId]
      );
  
      console.log('Permissions from database:', permissions);
  
      if (permissions.length === 0) {
        console.log('No permissions found for this location');
        return res.status(403).json({ error: 'User not authorized in this location' });
      }
  
      const allowedGrades = permissions[0].allowed_grades.split(',');
      console.log('Allowed grades:', allowedGrades);
  
      if (allowedGrades.includes(employeeGrade)) {
        console.log('User authorized');
        return res.json({ message: 'Check-in request approved' });
      } else {
        console.log('User not authorized');
        return res.status(403).json({ error: 'User not authorized in this location' });
      }
    } catch (error) {
      console.error('Check-in request error:', error);
      res.status(500).json({ error: 'Check-in request failed' });
    }
  });

// Check-in endpoint
app.post('/checkin', authenticateToken, async (req, res) => {
  try {
    const { locationId, latitude, longitude } = req.body;
    const employeeId = req.user.id;

    // Check if within 20 meters
    const [locationRows] = await pool.query('SELECT latitude, longitude FROM locations WHERE id = ?', [locationId]);
    if (locationRows.length === 0) {
      return res.status(404).json({ error: 'Location not found' });
    }

    const location = locationRows[0];
    const distance = calculateDistance(latitude, longitude, location.latitude, location.longitude);

    if (distance > 20) {
      return res.status(403).json({ error: 'Out of range' });
    }

    // Check for 6 check-ins limit within 8 minutes
    const [checkinsCount] = await pool.query(
      'SELECT COUNT(*) as count FROM checkins WHERE employee_id = ? AND checkin_time > DATE_SUB(NOW(), INTERVAL 8 MINUTE)',
      [employeeId]
    );

    if (checkinsCount[0].count >= 6) {
      return res.status(403).json({ error: 'Exceeded check-in limit' });
    }

    // Perform check-in
    await pool.query(
      'INSERT INTO checkins (employee_id, location_id, checkin_time) VALUES (?, ?, NOW())',
      [employeeId, locationId]
    );

    res.json({ message: 'Check-in successful' });
  } catch (error) {
    res.status(500).json({ error: 'Check-in failed' });
  }
});

// Get check-in history endpoint
app.get('/checkin-history', authenticateToken, async (req, res) => {
  try {
    const employeeId = req.user.id;

    const [checkins] = await pool.query(
      'SELECT c.checkin_time, l.name as location_name FROM checkins c JOIN locations l ON c.location_id = l.id WHERE c.employee_id = ? ORDER BY c.checkin_time DESC LIMIT 10',
      [employeeId]
    );

    res.json(checkins);
  } catch (error) {
    res.status(500).json({ error: 'Failed to retrieve check-in history' });
  }
});


function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
  
    if (token == null) return res.sendStatus(401);
  
    jwt.verify(token, JWT_SECRET, (err, user) => {
      if (err) return res.sendStatus(403);
      console.log('Decoded token:', user);
      req.user = user;
      next();
    });
}

app.get('/locations', authenticateToken, async (req, res) => {
    try {
      console.log('Fetching locations...');
      const [rows] = await pool.query('SELECT * FROM locations');
      console.log('Locations fetched:', rows);
      res.json(rows);
    } catch (error) {
      console.error('Error fetching locations:', error);
      res.status(500).json({ error: 'Failed to retrieve locations' });
    }
});

function calculateDistance(lat1, lon1, lat2, lon2) {
  // Haversine formula to calculate distance between two points on Earth
  const R = 6371e3; // Earth's radius in meters
  const φ1 = lat1 * Math.PI / 180;
  const φ2 = lat2 * Math.PI / 180;
  const Δφ = (lat2 - lat1) * Math.PI / 180;
  const Δλ = (lon2 - lon1) * Math.PI / 180;

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
            Math.cos(φ1) * Math.cos(φ2) *
            Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // Distance in meters
}

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));