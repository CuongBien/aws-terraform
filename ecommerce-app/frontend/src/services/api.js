import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api'

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
})

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
