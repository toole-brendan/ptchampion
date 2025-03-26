// Production server that includes authentication routes
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';
import { createServer } from 'http';
import passport from 'passport';
import session from 'express-session';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { Strategy as LocalStrategy } from 'passport-local';
import { Strategy as JwtStrategy, ExtractJwt } from 'passport-jwt';

// Initialize __dirname in ES module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Create Express app
const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Session configuration
const sessionSecret = process.env.SESSION_SECRET || 'secure-session-secret-key';
app.use(session({
  secret: sessionSecret,
  resave: false,
  saveUninitialized: false,
  cookie: { secure: process.env.NODE_ENV === 'production' }
}));

// Initialize passport
app.use(passport.initialize());
app.use(passport.session());

// JWT configuration
const jwtSecret = process.env.JWT_SECRET || 'secure-jwt-secret-key';
const jwtOptions = {
  jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
  secretOrKey: jwtSecret
};

// Mock database for users (in production, replace this with real database)
const users = [];

// Configure passport local strategy
passport.use(new LocalStrategy({ usernameField: 'email' },
  async (email, password, done) => {
    try {
      // Find user with the provided email
      const user = users.find(u => u.email === email);
      
      // If user not found, return error
      if (!user) {
        return done(null, false, { message: 'Invalid email or password' });
      }
      
      // Compare provided password with stored hash
      const isMatch = await bcrypt.compare(password, user.password);
      
      // If passwords match, return user
      if (isMatch) {
        return done(null, user);
      }
      
      // Otherwise, return error
      return done(null, false, { message: 'Invalid email or password' });
    } catch (err) {
      return done(err);
    }
  }
));

// Configure passport JWT strategy
passport.use(new JwtStrategy(jwtOptions, (jwtPayload, done) => {
  try {
    // Find user by ID in JWT payload
    const user = users.find(u => u.id === jwtPayload.sub);
    
    // If user found, return user
    if (user) {
      return done(null, user);
    }
    
    // Otherwise, return false
    return done(null, false);
  } catch (err) {
    return done(err, false);
  }
}));

// Serialize and deserialize user for sessions
passport.serializeUser((user, done) => {
  done(null, user.id);
});

passport.deserializeUser((id, done) => {
  const user = users.find(u => u.id === id);
  done(null, user);
});

// Authentication middleware
const authenticate = (req, res, next) => {
  // Check for session authentication
  if (req.isAuthenticated()) {
    return next();
  }
  
  // Otherwise check for JWT authentication
  return passport.authenticate('jwt', { session: false })(req, res, next);
};

// Serve static files from dist/public
const publicDir = path.join(__dirname, 'dist/public');
app.use(express.static(publicDir));

// Auth routes
// Login route
app.post('/api/auth/login', (req, res, next) => {
  passport.authenticate('local', (err, user, info) => {
    if (err) {
      return next(err);
    }
    
    if (!user) {
      return res.status(401).json({ message: info.message || 'Authentication failed' });
    }
    
    req.login(user, (err) => {
      if (err) {
        return next(err);
      }
      
      // Create JWT
      const token = jwt.sign(
        { sub: user.id, email: user.email },
        jwtSecret,
        { expiresIn: '24h' }
      );
      
      // Return user and token
      return res.json({
        user: {
          id: user.id,
          email: user.email,
          name: user.name
        },
        token
      });
    });
  })(req, res, next);
});

// Register route
app.post('/api/auth/register', async (req, res) => {
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
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Create user
    const user = {
      id: Date.now().toString(),
      email,
      password: hashedPassword,
      name: name || email.split('@')[0]
    };
    
    // Add user to "database"
    users.push(user);
    
    // Create JWT
    const token = jwt.sign(
      { sub: user.id, email: user.email },
      jwtSecret,
      { expiresIn: '24h' }
    );
    
    // Return user and token
    res.status(201).json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name
      },
      token
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Logout route
app.post('/api/auth/logout', (req, res) => {
  req.logout(function(err) {
    if (err) { return next(err); }
    res.json({ message: 'Logged out successfully' });
  });
});

// Protected route example
app.get('/api/profile', authenticate, (req, res) => {
  res.json({ 
    user: req.user,
    message: 'This is a protected route'
  });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

// For all other routes, serve index.html (SPA fallback)
app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

// Start server
const port = process.env.PORT || 3000;
app.listen(port, '0.0.0.0', () => {
  console.log(`Production server running at http://localhost:${port}`);
});
