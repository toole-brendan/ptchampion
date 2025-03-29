import express from 'express';
import session from 'express-session';
import { db } from './db';
import { storage } from './storage';
import bcrypt from 'bcrypt';
import cors from 'cors';

// Extend express-session with our custom properties
declare module 'express-session' {
  export interface SessionData {
    userId?: number;
    username?: string;
  }
}

// This is a standalone script that can be used to test and debug session issues
export function createSessionTestApp() {
  const app = express();
  
  // Configure CORS first
  const clientUrl = process.env.CLIENT_URL || "http://localhost:5173";
  app.use(cors({
    origin: clientUrl,
    credentials: true,
  }));
  
  // Parse JSON bodies
  app.use(express.json());
  
  // Configure session middleware with explicit settings for debugging
  const sessionSettings: session.SessionOptions = {
    secret: process.env.SESSION_SECRET || "pt-champion-secret",
    resave: true, // Changed to true to ensure session is always saved
    saveUninitialized: true, // Changed to true to create session even for non-authenticated users
    store: storage.sessionStore,
    cookie: {
      secure: false, // Set to false for testing, even in production
      maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
      sameSite: 'lax', // Set as literal value
      httpOnly: true,
      path: '/'
    },
    name: 'ptchampion.sid' // Explicit name for easier debugging
  };
  
  app.set("trust proxy", 1);
  app.use(session(sessionSettings));
  
  // Simple login route that directly sets session data
  app.post('/test-login', async (req, res) => {
    try {
      const { username, password } = req.body;
      
      // Get user from database
      const user = await storage.getUserByUsername(username);
      if (!user) {
        return res.status(401).json({ message: 'User not found' });
      }
      
      // Verify password
      const isValid = await bcrypt.compare(password, user.password);
      if (!isValid) {
        return res.status(401).json({ message: 'Invalid password' });
      }
      
      // Set session data
      req.session.userId = user.id;
      req.session.username = user.username;
      
      // Force save session - important for debugging
      req.session.save((err) => {
        if (err) {
          console.error('Session save error:', err);
          return res.status(500).json({ message: 'Failed to save session', error: err instanceof Error ? err.message : String(err) });
        }
        
        // Return session info for debugging
        return res.status(200).json({
          message: 'Login successful',
          user: {
            id: user.id,
            username: user.username
          },
          session: {
            id: req.session.id,
            cookie: req.session.cookie
          }
        });
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({ 
        message: 'Server error', 
        error: error instanceof Error ? error.message : String(error) 
      });
    }
  });
  
  // Check session route
  app.get('/test-session', (req, res) => {
    if (req.session && req.session.userId) {
      res.status(200).json({
        authenticated: true,
        userId: req.session.userId,
        username: req.session.username,
        sessionId: req.session.id
      });
    } else {
      res.status(401).json({
        authenticated: false,
        sessionInfo: {
          exists: !!req.session,
          id: req.session?.id
        }
      });
    }
  });
  
  // Debug route to view session info
  app.get('/debug-session', (req, res) => {
    res.json({
      session: {
        id: req.session.id,
        exists: !!req.session,
        hasUserId: !!req.session.userId,
        cookie: req.session.cookie,
        sessionObject: req.session
      },
      headers: {
        cookie: req.headers.cookie
      }
    });
  });
  
  return app;
}
