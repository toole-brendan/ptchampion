// Simplified server for production
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

// Initialize __dirname in ES module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Create Express app
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Mock database for users (in production, replace this with real database)
const users = [];

// Serve static files from dist/public
const publicDir = path.join(__dirname, 'dist/public');
app.use(express.static(publicDir));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Server is running',
    timestamp: new Date().toISOString(),
    version: 'simplified'
  });
});

// Basic auth endpoints for testing
app.post('/api/auth/register', (req, res) => {
  try {
    const { email, password, name } = req.body;
    
    // Validate input
    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }
    
    // Check if user already exists
    if (users.some(u => u.email === email)) {
      return res.status(400).json({ message: 'User with this email already exists' });
    }
    
    // Create user (without hashing for simplicity)
    const user = {
      id: Date.now().toString(),
      email,
      password,
      name: name || email.split('@')[0]
    };
    
    // Add user to "database"
    users.push(user);
    console.log(`New user registered: ${email}`);
    
    // Return user without password
    res.status(201).json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name
      },
      token: 'test-token-for-development'
    });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/auth/login', (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Find user
    const user = users.find(u => u.email === email && u.password === password);
    
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }
    
    // Return user without password
    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name
      },
      token: 'test-token-for-development'
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// API routes for debugging
app.get('/api/debug/users', (req, res) => {
  // Return all users without passwords
  const safeUsers = users.map(u => ({
    id: u.id,
    email: u.email,
    name: u.name
  }));
  res.json(safeUsers);
});

// For all other routes, serve index.html (SPA fallback)
app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

// Start server
const port = process.env.PORT || 3000;
app.listen(port, '0.0.0.0', () => {
  console.log(`Simplified server running at http://localhost:${port}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
}); 