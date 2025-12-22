import express from 'express'
import pool from '../config/database.js'

const router = express.Router()

// Get cart items
router.get('/:sessionId', async (req, res) => {
  try {
    const [items] = await pool.query(`
      SELECT c.*, p.name, p.price, p.image_url, p.category
      FROM cart c
      JOIN products p ON c.product_id = p.id
      WHERE c.session_id = ?
    `, [req.params.sessionId])
    
    res.json({ items })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// Add to cart
router.post('/add', async (req, res) => {
  try {
    const { sessionId, productId, quantity } = req.body
    
    // Check if product exists and has stock
    const [products] = await pool.query('SELECT * FROM products WHERE id = ?', [productId])
    if (products.length === 0) {
      return res.status(404).json({ error: 'Product not found' })
    }
    
    if (products[0].stock < quantity) {
      return res.status(400).json({ error: 'Insufficient stock' })
    }
    
    // Add or update cart item
    await pool.query(`
      INSERT INTO cart (session_id, product_id, quantity)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE quantity = quantity + ?
    `, [sessionId, productId, quantity, quantity])
    
    res.json({ message: 'Product added to cart' })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// Update cart item quantity
router.put('/update', async (req, res) => {
  try {
    const { sessionId, productId, quantity } = req.body
    
    if (quantity <= 0) {
      await pool.query('DELETE FROM cart WHERE session_id = ? AND product_id = ?', 
        [sessionId, productId])
    } else {
      await pool.query('UPDATE cart SET quantity = ? WHERE session_id = ? AND product_id = ?',
        [quantity, sessionId, productId])
    }
    
    res.json({ message: 'Cart updated' })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// Remove from cart
router.delete('/:sessionId/:productId', async (req, res) => {
  try {
    await pool.query('DELETE FROM cart WHERE session_id = ? AND product_id = ?',
      [req.params.sessionId, req.params.productId])
    
    res.json({ message: 'Product removed from cart' })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// Clear cart
router.delete('/:sessionId', async (req, res) => {
  try {
    await pool.query('DELETE FROM cart WHERE session_id = ?', [req.params.sessionId])
    res.json({ message: 'Cart cleared' })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

export default router
