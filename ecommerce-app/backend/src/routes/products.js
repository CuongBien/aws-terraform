import express from 'express'
import pool from '../config/database.js'

const router = express.Router()

// Get all products
router.get('/', async (req, res) => {
  try {
    const [products] = await pool.query('SELECT * FROM products ORDER BY created_at DESC')
    res.json(products)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// Get product by ID
router.get('/:id', async (req, res) => {
  try {
    const [products] = await pool.query('SELECT * FROM products WHERE id = ?', [req.params.id])
    
    if (products.length === 0) {
      return res.status(404).json({ error: 'Product not found' })
    }
    
    res.json(products[0])
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// Get products by category
router.get('/category/:category', async (req, res) => {
  try {
    const [products] = await pool.query(
      'SELECT * FROM products WHERE category = ? ORDER BY created_at DESC',
      [req.params.category]
    )
    res.json(products)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

export default router
