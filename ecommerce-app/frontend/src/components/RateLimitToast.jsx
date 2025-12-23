// Rate Limit Toast Notification Component
// Shows user-friendly message when rate limited

import React, { useState, useEffect } from 'react'
import { formatRetryTime } from '../utils/rateLimitHandler'

const RateLimitToast = () => {
  const [show, setShow] = useState(false)
  const [retryAfter, setRetryAfter] = useState(null)
  const [message, setMessage] = useState('')

  useEffect(() => {
    const handleRateLimit = (event) => {
      setShow(true)
      setRetryAfter(event.detail.retryAfter)
      setMessage(event.detail.message || 'Too many requests. Please slow down.')

      // Auto-hide after showing
      const hideDelay = event.detail.retryAfter 
        ? Math.min(event.detail.retryAfter - Date.now(), 10000) 
        : 5000

      setTimeout(() => setShow(false), hideDelay)
    }

    window.addEventListener('rateLimitExceeded', handleRateLimit)
    return () => window.removeEventListener('rateLimitExceeded', handleRateLimit)
  }, [])

  if (!show) return null

  return (
    <div style={{
      position: 'fixed',
      top: '20px',
      right: '20px',
      backgroundColor: '#ff6b6b',
      color: 'white',
      padding: '16px 24px',
      borderRadius: '8px',
      boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
      zIndex: 10000,
      maxWidth: '400px',
      animation: 'slideIn 0.3s ease-out'
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/>
        </svg>
        <div>
          <div style={{ fontWeight: 'bold', marginBottom: '4px' }}>
            Rate Limit Exceeded
          </div>
          <div style={{ fontSize: '14px', opacity: 0.9 }}>
            {message}
          </div>
          {retryAfter && (
            <div style={{ fontSize: '12px', marginTop: '4px', opacity: 0.8 }}>
              Try again in {formatRetryTime(retryAfter)}
            </div>
          )}
        </div>
        <button
          onClick={() => setShow(false)}
          style={{
            marginLeft: 'auto',
            background: 'none',
            border: 'none',
            color: 'white',
            cursor: 'pointer',
            fontSize: '20px',
            padding: '0',
            width: '24px',
            height: '24px'
          }}
        >
          ×
        </button>
      </div>
      <style>{`
        @keyframes slideIn {
          from {
            transform: translateX(100%);
            opacity: 0;
          }
          to {
            transform: translateX(0);
            opacity: 1;
          }
        }
      `}</style>
    </div>
  )
}

export default RateLimitToast
