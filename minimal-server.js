// Minimal server using only built-in modules
import http from 'http';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

// Initialize __dirname in ES module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Mock database for users
const users = [];

// Create HTTP server
const server = http.createServer((req, res) => {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  // Handle OPTIONS requests for CORS preflight
  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    res.end();
    return;
  }
  
  // Parse URL
  const url = new URL(req.url, `http://${req.headers.host}`);
  const pathname = url.pathname;
  
  console.log(`${req.method} ${pathname}`);
  
  // Health check endpoint
  if (pathname === '/api/health' && req.method === 'GET') {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({
      status: 'ok',
      message: 'Server is running',
      timestamp: new Date().toISOString(),
      version: 'minimal'
    }));
    return;
  }
  
  // User registration endpoint
  if (pathname === '/api/auth/register' && req.method === 'POST') {
    let body = '';
    
    req.on('data', chunk => {
      body += chunk.toString();
    });
    
    req.on('end', () => {
      try {
        const { email, password, name } = JSON.parse(body);
        
        // Validate input
        if (!email || !password) {
          res.statusCode = 400;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ message: 'Email and password are required' }));
          return;
        }
        
        // Check if user already exists
        if (users.some(u => u.email === email)) {
          res.statusCode = 400;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ message: 'User with this email already exists' }));
          return;
        }
        
        // Create user
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
        res.statusCode = 201;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({
          user: {
            id: user.id,
            email: user.email,
            name: user.name
          },
          token: 'test-token-for-development'
        }));
      } catch (err) {
        console.error('Registration error:', err);
        res.statusCode = 500;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ message: 'Server error' }));
      }
    });
    return;
  }
  
  // User login endpoint
  if (pathname === '/api/auth/login' && req.method === 'POST') {
    let body = '';
    
    req.on('data', chunk => {
      body += chunk.toString();
    });
    
    req.on('end', () => {
      try {
        const { email, password } = JSON.parse(body);
        
        // Find user
        const user = users.find(u => u.email === email && u.password === password);
        
        if (!user) {
          res.statusCode = 401;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ message: 'Invalid credentials' }));
          return;
        }
        
        // Return user without password
        res.statusCode = 200;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({
          user: {
            id: user.id,
            email: user.email,
            name: user.name
          },
          token: 'test-token-for-development'
        }));
      } catch (err) {
        console.error('Login error:', err);
        res.statusCode = 500;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ message: 'Server error' }));
      }
    });
    return;
  }
  
  // Debug endpoint to view users
  if (pathname === '/api/debug/users' && req.method === 'GET') {
    // Return all users without passwords
    const safeUsers = users.map(u => ({
      id: u.id,
      email: u.email,
      name: u.name
    }));
    res.statusCode = 200;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify(safeUsers));
    return;
  }
  
  // Catch-all for API calls
  if (pathname.startsWith('/api/')) {
    res.statusCode = 404;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ message: 'API endpoint not found' }));
    return;
  }
  
  // Serve static files or default to index.html
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Minimal server running');
});

// Start server
const port = process.env.PORT || 3000;
server.listen(port, '0.0.0.0', () => {
  console.log(`Minimal server running at http://localhost:${port}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
}); 