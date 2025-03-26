import passport from "passport";
import { Strategy as LocalStrategy } from "passport-local";
import { Strategy as JwtStrategy, ExtractJwt } from "passport-jwt";
import { Express, Request } from "express";
import session from "express-session";
import bcrypt from "bcrypt";
import { storage } from "./storage";
import { User as SelectUser } from "@shared/schema";
import jwt from "jsonwebtoken";
import connectPg from "connect-pg-simple";

declare global {
  namespace Express {
    interface User extends SelectUser {}
  }
}

// JWT settings
const JWT_SECRET = process.env.JWT_SECRET || "pt-champion-jwt-secret";
const JWT_EXPIRES = process.env.JWT_EXPIRES || "7d";

const SALT_ROUNDS = 12;

async function hashPassword(password: string) {
  return bcrypt.hash(password, SALT_ROUNDS);
}

async function comparePasswords(supplied: string, stored: string) {
  return bcrypt.compare(supplied, stored);
}

// Generate a JWT token for a user
function generateToken(user: SelectUser) {
  const payload = {
    id: user.id,
    username: user.username,
  };
  
  // Using proper typing for JWT
  const secret = JWT_SECRET;
  const options = { expiresIn: JWT_EXPIRES };
  
  // @ts-ignore - Working around jsonwebtoken type issues
  return jwt.sign(payload, secret, options);
}

// Function to authenticate with token or session
function authenticate(req: Request): Promise<SelectUser | null> {
  return new Promise((resolve) => {
    // If already authenticated via session
    if (req.isAuthenticated() && req.user) {
      return resolve(req.user);
    }
    
    // Check for JWT authorization
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      try {
        const decoded = jwt.verify(token, JWT_SECRET) as { id: number };
        storage.getUser(decoded.id)
          .then(user => resolve(user || null))
          .catch(() => resolve(null));
      } catch (err) {
        resolve(null);
      }
    } else {
      resolve(null);
    }
  });
}

export function setupAuth(app: Express) {
  // Use the existing sessionStore from storage
  const sessionSettings: session.SessionOptions = {
    secret: process.env.SESSION_SECRET || "pt-champion-secret",
    resave: false,
    saveUninitialized: false,
    store: storage.sessionStore as any,
    cookie: {
      secure: process.env.NODE_ENV === "production",
      maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
    }
  };

  app.set("trust proxy", 1);
  app.use(session(sessionSettings));
  app.use(passport.initialize());
  app.use(passport.session());

  // Local strategy for username/password auth
  passport.use(
    new LocalStrategy(async (username, password, done) => {
      try {
        const user = await storage.getUserByUsername(username);
        if (!user || !(await comparePasswords(password, user.password))) {
          return done(null, false);
        } else {
          return done(null, user);
        }
      } catch (err) {
        return done(err);
      }
    }),
  );
  
  // JWT strategy for token-based auth
  passport.use(
    new JwtStrategy(
      {
        jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
        secretOrKey: JWT_SECRET,
      },
      async (payload, done) => {
        try {
          const user = await storage.getUser(payload.id);
          if (!user) {
            return done(null, false);
          }
          return done(null, user);
        } catch (err) {
          return done(err, false);
        }
      }
    )
  );

  passport.serializeUser((user, done) => done(null, user.id));
  passport.deserializeUser(async (id: number, done) => {
    try {
      const user = await storage.getUser(id);
      done(null, user);
    } catch (err) {
      done(err);
    }
  });

  // Register endpoint - supports both web and mobile
  app.post("/api/register", async (req, res, next) => {
    try {
      const existingUser = await storage.getUserByUsername(req.body.username);
      if (existingUser) {
        return res.status(400).json({ message: "Username already exists" });
      }

      // Handle backward compatibility with the database schema
      // Only include fields that exist in the current database 
      const userData = {
        username: req.body.username,
        password: await hashPassword(req.body.password),
        // Only include these fields if they are provided
        ...(req.body.location ? { location: req.body.location } : {}),
        ...(req.body.latitude ? { latitude: req.body.latitude } : {}),
        ...(req.body.longitude ? { longitude: req.body.longitude } : {})
      };

      // Try to create the user with available fields only
      const user = await storage.createUser(userData);
      
      // For web clients: create session
      if (req.headers['x-client-platform'] !== 'mobile') {
        req.login(user, (err) => {
          if (err) return next(err);
          res.status(201).json({ user });
        });
        return;
      }
      
      // For mobile clients: return JWT token
      const token = generateToken(user);
      res.status(201).json({ 
        user, 
        token,
        expiresIn: JWT_EXPIRES 
      });
    } catch (err) {
      console.error("Registration error:", err);
      
      // Check for specific database schema errors
      if (err instanceof Error && 
          err.message && 
          err.message.includes("column") && 
          err.message.includes("does not exist")) {
        return res.status(500).json({ 
          message: "Database schema needs migration. Please run migrations first.",
          error: err.message 
        });
      }
      
      next(err);
    }
  });

  // Login endpoint - supports both web and mobile
  app.post("/api/login", passport.authenticate("local", { session: true }), (req, res) => {
    // For mobile clients: return JWT token
    if (req.headers['x-client-platform'] === 'mobile' && req.user) {
      const token = generateToken(req.user);
      return res.status(200).json({
        user: req.user,
        token,
        expiresIn: JWT_EXPIRES
      });
    }
    
    // For web clients: return user info (session already created)
    res.status(200).json({ user: req.user });
  });

  // Token-based login endpoint (specifically for mobile)
  app.post("/api/token-login", passport.authenticate("local", { session: false }), (req, res) => {
    if (req.user) {
      const token = generateToken(req.user);
      res.status(200).json({
        user: req.user,
        token,
        expiresIn: JWT_EXPIRES
      });
    } else {
      res.status(401).json({ message: "Authentication failed" });
    }
  });

  // Validate token endpoint (for mobile clients to check token validity)
  app.get("/api/validate-token", passport.authenticate("jwt", { session: false }), (req, res) => {
    res.status(200).json({ user: req.user });
  });

  // Logout endpoint - handles both session and token
  app.post("/api/logout", (req, res, next) => {
    // For web clients with session
    if (req.isAuthenticated()) {
      req.logout((err) => {
        if (err) return next(err);
        res.sendStatus(200);
      });
    } else {
      // For mobile clients: token invalidation happens client-side
      // by removing the token from storage
      res.sendStatus(200);
    }
  });

  // Get user info - supports both auth methods
  app.get("/api/user", async (req, res) => {
    const user = await authenticate(req);
    if (!user) return res.sendStatus(401);
    res.json(user);
  });
  
  // Update user location - supports both auth methods
  app.post("/api/user/location", async (req, res, next) => {
    const user = await authenticate(req);
    if (!user) return res.sendStatus(401);
    
    try {
      const { latitude, longitude } = req.body;
      
      // Handle numbers or numeric strings
      const lat = typeof latitude === 'string' ? parseFloat(latitude) : latitude;
      const lng = typeof longitude === 'string' ? parseFloat(longitude) : longitude;
      
      if (isNaN(lat) || isNaN(lng)) {
        return res.status(400).json({ message: "Invalid coordinates" });
      }
      
      const updatedUser = await storage.updateUserLocation(user.id, lat, lng);
      res.json(updatedUser);
    } catch (err) {
      next(err);
    }
  });
}
