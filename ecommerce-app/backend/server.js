import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import { initDatabase } from './src/config/database.js'
import productsRouter from './src/routes/products.js'
import cartRouter from './src/routes/cart.js'
import ordersRouter from './src/routes/orders.js'
import categoriesRouter from './src/routes/categories.js'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3000

// Middleware
app.use(cors())
app.use(express.json())
app.use(express.urlencoded({ extended: true }))

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'E-commerce API is running' })
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

// API Routes
app.use('/api/products', productsRouter)
app.use('/api/cart', cartRouter)
app.use('/api/orders', ordersRouter)
app.use('/api/categories', categoriesRouter)

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
