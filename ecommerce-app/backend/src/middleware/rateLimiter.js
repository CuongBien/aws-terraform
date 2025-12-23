// Advanced Rate Limiting Middleware
// Provides custom rate limiting strategies for different scenarios

import rateLimit from 'express-rate-limit'
import slowDown from 'express-slow-down'

// ===== RATE LIMIT CONFIGURATIONS =====

// Authentication endpoints - very strict
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Max 5 attempts
  skipSuccessfulRequests: true, // Don't count successful requests
  standardHeaders: true,
  legacyHeaders: false,
  message: { 
    error: 'Too many authentication attempts',
    message: 'Please wait 15 minutes before trying again.'
  }
})

// CSRF token endpoint - moderate limit
export const csrfTokenLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 10, // Max 10 token requests
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many token requests' }
})

// Search endpoints - moderate with slowdown
export const searchLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 60, // Max 60 searches per minute
  standardHeaders: true,
  legacyHeaders: false
})

export const searchSpeedLimiter = slowDown({
  windowMs: 1 * 60 * 1000,
  delayAfter: 30, // Start slowing after 30 requests
  delayMs: (hits) => hits * 50 // 50ms per request
})

// ===== CUSTOM LIMITERS BY SESSION/USER =====

// Session-based limiter (uses sessionId from request body/query)
export const sessionBasedLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 50,
  keyGenerator: (req) => {
    // Use sessionId if available, fallback to IP
    return req.body?.sessionId || req.query?.sessionId || req.ip
  },
  standardHeaders: true,
  legacyHeaders: false,
  message: { 
    error: 'Session rate limit exceeded',
    message: 'Your session has made too many requests.'
  }
})

// ===== SKIP CONDITIONS =====

// Skip rate limiting for health checks and monitoring
export const skipHealthCheck = (req) => {
  return req.path === '/health' || req.path === '/api/health'
}

// Skip for internal/trusted IPs (customize as needed)
export const skipTrustedIPs = (req) => {
  const trustedIPs = process.env.TRUSTED_IPS?.split(',') || []
  return trustedIPs.includes(req.ip)
}

// ===== RATE LIMIT INFO MIDDLEWARE =====

// Add rate limit info to response headers for transparency
export const rateLimitHeaders = (req, res, next) => {
  // These headers are added automatically by express-rate-limit
  // This middleware is for custom logging/monitoring
  res.on('finish', () => {
    if (res.getHeader('RateLimit-Limit')) {
      const limit = res.getHeader('RateLimit-Limit')
      const remaining = res.getHeader('RateLimit-Remaining')
      const reset = res.getHeader('RateLimit-Reset')
      
      if (remaining < limit * 0.2) { // Less than 20% remaining
        console.warn(`Rate limit warning: ${req.ip} on ${req.path} - ${remaining}/${limit} remaining`)
      }
    }
  })
  next()
}

// ===== DYNAMIC RATE LIMITING =====

// Adjust rate limits based on server load (example)
export const dynamicLimiter = (baseMax) => {
  return rateLimit({
    windowMs: 15 * 60 * 1000,
    max: (req) => {
      // Could check server metrics here and adjust
      // For now, just return base max
      return baseMax
    },
    standardHeaders: true,
    legacyHeaders: false
  })
}
