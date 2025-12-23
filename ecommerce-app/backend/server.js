import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import cookieParser from 'cookie-parser'
import csrf from 'csurf'
import rateLimit from 'express-rate-limit'
import slowDown from 'express-slow-down'
import { initDatabase } from './src/config/database.js'
import productsRouter from './src/routes/products.js'
import cartRouter from './src/routes/cart.js'
import ordersRouter from './src/routes/orders.js'
import categoriesRouter from './src/routes/categories.js'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3000

// Middleware
app.use(cors({
  origin: true, // Allow all origins in development
  credentials: true // Allow cookies
}))
app.use(express.json())
app.use(express.urlencoded({ extended: true }))
app.use(cookieParser())

// ===== RATE LIMITING & THROTTLING =====

// General API rate limiter - applies to all API routes
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Max 100 requests per IP per window
  standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
  legacyHeaders: false, // Disable `X-RateLimit-*` headers
  message: { error: 'Too many requests, please try again later.' },
  handler: (req, res) => {
    console.warn(`Rate limit exceeded for IP: ${req.ip} on ${req.path}`)
    res.status(429).json({ 
      error: 'Too many requests',
      message: 'You have exceeded the rate limit. Please try again later.',
      retryAfter: req.rateLimit.resetTime
    })
  }
})

// Strict limiter for write operations (cart, orders)
const strictLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 30, // Max 30 write operations per IP per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many write operations, please slow down.' },
  handler: (req, res) => {
    console.warn(`Strict rate limit exceeded for IP: ${req.ip} on ${req.path}`)
    res.status(429).json({ 
      error: 'Too many operations',
      message: 'You are making too many changes. Please wait before trying again.',
      retryAfter: req.rateLimit.resetTime
    })
  }
})

// Speed limiter - slows down repeated requests instead of blocking
const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000, // 15 minutes
  delayAfter: 50, // Allow 50 requests per window at full speed
  delayMs: (hits) => hits * 100, // Add 100ms delay per request after threshold
  maxDelayMs: 5000, // Maximum delay of 5 seconds
})

// CSRF Protection
const csrfProtection = csrf({ cookie: true })

// Health check (no CSRF needed)
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'E-commerce API is running' })
})

// CSRF Token endpoint (GET request, no CSRF needed)
app.get('/api/csrf-token', csrfProtection, (req, res) => {
  res.json({ csrfToken: req.csrfToken() })
})

// API Root
app.get('/api', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'E-commerce API',
    endpoints: {
      products: '/api/products',
      cart: '/api/cart',
      orders: '/api/orders',
      categories: '/api/categories'
    }
  })
})

// API Routes (GET requests - no CSRF protection needed)
// Apply general API limiter + speed limiter for read operations
app.use('/api/products', apiLimiter, speedLimiter, productsRouter)
app.use('/api/categories', apiLimiter, speedLimiter, categoriesRouter)

// API Routes (POST/PUT/DELETE - CSRF protection + strict rate limiting)
app.use('/api/cart', apiLimiter, strictLimiter, csrfProtection, cartRouter)
app.use('/api/orders', apiLimiter, strictLimiter, csrfProtection, ordersRouter)

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack)
  res.status(500).json({ 
    error: 'Something went wrong!',
    message: err.message 
  })
})

// Initialize database and start server
async function startServer() {
  try {
    await initDatabase()
    console.log('✓ Database initialized')
    
    app.listen(PORT, () => {
      console.log(`✓ Server running on port ${PORT}`)
      console.log(`✓ API: http://localhost:${PORT}/api`)
      console.log(`✓ Health: http://localhost:${PORT}/health`)
    })
  } catch (error) {
    console.error('Failed to start server:', error)
    process.exit(1)
  }
}

startServer()
