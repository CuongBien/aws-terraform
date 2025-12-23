import axios from 'axios'
import { setupRateLimitInterceptor } from '../utils/rateLimitHandler'

// Use relative path so nginx can proxy to backend
const API_URL = import.meta.env.VITE_API_URL || '/api'

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  },
  withCredentials: true // Enable cookies for CSRF
})

// Setup rate limit tracking
setupRateLimitInterceptor(api)

// CSRF Token cache
let csrfToken = null

// Function to get CSRF token
const getCSRFToken = async () => {
  if (csrfToken) return csrfToken
  
  try {
    const response = await axios.get('/api/csrf-token', { 
      withCredentials: true 
    })
    csrfToken = response.data.csrfToken
    return csrfToken
  } catch (error) {
    console.error('Failed to get CSRF token:', error)
    return null
  }
}

// Request interceptor to add CSRF token for state-changing requests
api.interceptors.request.use(async (config) => {
  // Only add CSRF token for POST, PUT, DELETE, PATCH
  if (['post', 'put', 'delete', 'patch'].includes(config.method.toLowerCase())) {
    const token = await getCSRFToken()
    if (token) {
      config.headers['X-CSRF-Token'] = token
    }
  }
  return config
}, (error) => {
  return Promise.reject(error)
})

// Response interceptor to handle CSRF errors
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    // If CSRF token is invalid, refresh and retry
    if (error.response?.status === 403 && error.response?.data?.code === 'EBADCSRFTOKEN') {
      console.warn('CSRF token invalid, refreshing...')
      csrfToken = null // Clear cached token
      
      // Retry the request
      const token = await getCSRFToken()
      if (token) {
        error.config.headers['X-CSRF-Token'] = token
        return api.request(error.config)
      }
    }
    return Promise.reject(error)
  }
)

// Products
export const getProducts = () => api.get('/products')
export const getProduct = (id) => api.get(`/products/${id}`)
export const getProductsByCategory = (category) => api.get(`/products/category/${category}`)

// Cart
export const getCart = (sessionId) => api.get(`/cart/${sessionId}`)
export const addToCart = (sessionId, productId, quantity) => 
  api.post('/cart/add', { sessionId, productId, quantity })
export const updateCartItem = (sessionId, productId, quantity) =>
  api.put('/cart/update', { sessionId, productId, quantity })
export const removeFromCart = (sessionId, productId) =>
  api.delete(`/cart/${sessionId}/${productId}`)
export const clearCart = (sessionId) => api.delete(`/cart/${sessionId}`)

// Orders
export const createOrder = (orderData) => api.post('/orders', orderData)
export const getOrders = (sessionId) => api.get(`/orders/${sessionId}`)
export const getOrder = (orderId) => api.get(`/orders/detail/${orderId}`)

// Categories
export const getCategories = () => api.get('/categories')

export default api
