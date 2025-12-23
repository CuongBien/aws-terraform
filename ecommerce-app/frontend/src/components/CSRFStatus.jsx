// CSRF Protection Status Component
// Shows CSRF protection is active (for demo/security awareness)

import React, { useEffect, useState } from 'react'
import axios from 'axios'

const CSRFStatus = () => {
  const [csrfEnabled, setCsrfEnabled] = useState(false)

  useEffect(() => {
    // Check if CSRF token endpoint is available
    axios.get('/api/csrf-token', { withCredentials: true })
      .then(() => setCsrfEnabled(true))
      .catch(() => setCsrfEnabled(false))
  }, [])

  if (!csrfEnabled) return null

  return (
    <div style={{
      position: 'fixed',
      bottom: '20px',
      right: '20px',
      backgroundColor: '#28a745',
      color: 'white',
      padding: '8px 16px',
      borderRadius: '20px',
      fontSize: '12px',
      fontWeight: 'bold',
      boxShadow: '0 2px 8px rgba(0,0,0,0.2)',
      zIndex: 9999,
      display: 'flex',
      alignItems: 'center',
      gap: '8px'
    }}>
      <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
        <path d="M8 1a2 2 0 0 1 2 2v4H6V3a2 2 0 0 1 2-2zm3 6V3a3 3 0 0 0-6 0v4a2 2 0 0 0-2 2v5a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2z"/>
      </svg>
      CSRF Protected
    </div>
  )
}

export default CSRFStatus
