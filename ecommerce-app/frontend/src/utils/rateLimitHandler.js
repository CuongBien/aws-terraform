// Frontend Rate Limit Handler
// Detects rate limit responses and shows user-friendly messages

import axios from 'axios'

// Rate limit state
const rateLimitState = {
  isLimited: false,
  retryAfter: null,
  limitInfo: {
    limit: null,
    remaining: null,
    reset: null
  }
}

// Parse rate limit headers from response
export const parseRateLimitHeaders = (headers) => {
  return {
    limit: parseInt(headers['ratelimit-limit']) || null,
    remaining: parseInt(headers['ratelimit-remaining']) || null,
    reset: headers['ratelimit-reset'] 
      ? new Date(parseInt(headers['ratelimit-reset']) * 1000)
      : null
  }
}

// Check if rate limited
export const isRateLimited = () => rateLimitState.isLimited

// Get retry time
export const getRetryAfter = () => rateLimitState.retryAfter

// Get rate limit info
export const getRateLimitInfo = () => rateLimitState.limitInfo

// Setup rate limit interceptors for axios
export const setupRateLimitInterceptor = (axiosInstance) => {
  
  // Response interceptor to track rate limits
  axiosInstance.interceptors.response.use(
    (response) => {
      // Update rate limit info from headers
      if (response.headers) {
        rateLimitState.limitInfo = parseRateLimitHeaders(response.headers)
        
        // Warn if approaching limit (less than 20% remaining)
        const { limit, remaining } = rateLimitState.limitInfo
        if (limit && remaining !== null && remaining < limit * 0.2) {
          console.warn('⚠️ Approaching rate limit:', remaining, '/', limit, 'requests remaining')
        }
      }
      
      rateLimitState.isLimited = false
      return response
    },
    (error) => {
      if (error.response?.status === 429) {
        // Rate limited!
        rateLimitState.isLimited = true
        
        const retryAfter = error.response.headers['retry-after']
        if (retryAfter) {
          rateLimitState.retryAfter = new Date(Date.now() + parseInt(retryAfter) * 1000)
        }
        
        // Update rate limit info
        rateLimitState.limitInfo = parseRateLimitHeaders(error.response.headers)
        
        console.error('🚫 Rate limit exceeded:', error.response.data)
        
        // Dispatch custom event for UI to handle
        if (typeof window !== 'undefined') {
          window.dispatchEvent(new CustomEvent('rateLimitExceeded', {
            detail: {
              retryAfter: rateLimitState.retryAfter,
              message: error.response.data?.message || 'Too many requests',
              limitInfo: rateLimitState.limitInfo
            }
          }))
        }
      }
      
      return Promise.reject(error)
    }
  )
}

// React hook for rate limit status
export const useRateLimitStatus = () => {
  const [status, setStatus] = React.useState({
    isLimited: false,
    retryAfter: null,
    limitInfo: {}
  })
  
  React.useEffect(() => {
    const handleRateLimit = (event) => {
      setStatus({
        isLimited: true,
        retryAfter: event.detail.retryAfter,
        limitInfo: event.detail.limitInfo
      })
      
      // Auto-clear after retry time
      if (event.detail.retryAfter) {
        const timeUntilRetry = event.detail.retryAfter - Date.now()
        if (timeUntilRetry > 0) {
          setTimeout(() => {
            setStatus(prev => ({ ...prev, isLimited: false }))
          }, timeUntilRetry)
        }
      }
    }
    
    window.addEventListener('rateLimitExceeded', handleRateLimit)
    return () => window.removeEventListener('rateLimitExceeded', handleRateLimit)
  }, [])
  
  return status
}

// Utility: Wait until rate limit clears
export const waitForRateLimit = () => {
  return new Promise((resolve) => {
    if (!rateLimitState.isLimited) {
      resolve()
      return
    }
    
    const timeUntilRetry = rateLimitState.retryAfter 
      ? rateLimitState.retryAfter - Date.now()
      : 60000 // Default 1 minute
    
    if (timeUntilRetry > 0) {
      console.log(`⏳ Waiting ${Math.ceil(timeUntilRetry / 1000)}s for rate limit to clear...`)
      setTimeout(resolve, timeUntilRetry)
    } else {
      resolve()
    }
  })
}

// Utility: Format retry time for display
export const formatRetryTime = (retryAfter) => {
  if (!retryAfter) return 'unknown'
  
  const seconds = Math.ceil((retryAfter - Date.now()) / 1000)
  
  if (seconds < 60) return `${seconds} seconds`
  if (seconds < 3600) return `${Math.ceil(seconds / 60)} minutes`
  return `${Math.ceil(seconds / 3600)} hours`
}
