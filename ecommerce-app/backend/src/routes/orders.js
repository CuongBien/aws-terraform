import express from 'express'
import pool from '../config/database.js'

const router = express.Router()

// Create order
router.post('/', async (req, res) => {
  const connection = await pool.getConnection()
  
  try {
    await connection.beginTransaction()
    
    const { 
      sessionId, 
      customerName, 
      email, 
      phone, 
      address, 
      city, 
      zipCode, 
      paymentMethod,
      items,
      totalAmount 
    } = req.body
    
    // Create order
    const [orderResult] = await connection.query(`
      INSERT INTO orders (
        session_id, customer_name, email, phone, address, city, zip_code, 
        payment_method, total_amount, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    `, [sessionId, customerName, email, phone, address, city, zipCode, paymentMethod, totalAmount])
    
    const orderId = orderResult.insertId
    
    // Insert order items
    for (const item of items) {
      const [products] = await connection.query('SELECT name FROM products WHERE id = ?', [item.productId])
      
      await connection.query(`
        INSERT INTO order_items (order_id, product_id, product_name, quantity, price)
        VALUES (?, ?, ?, ?, ?)
      `, [orderId, item.productId, products[0].name, item.quantity, item.price])
      
      // Update stock
      await connection.query('UPDATE products SET stock = stock - ? WHERE id = ?', 
        [item.quantity, item.productId])
    }
    
    // Clear cart
    await connection.query('DELETE FROM cart WHERE session_id = ?', [sessionId])
    
    await connection.commit()
    
    res.json({ 
      message: 'Order created successfully', 
      orderId 
    })
  } catch (error) {
    await connection.rollback()
    res.status(500).json({ error: error.message })
  } finally {
    connection.release()
  }
})

// Get orders by session ID
router.get('/:sessionId', async (req, res) => {
  try {
    const [orders] = await pool.query(`
      SELECT * FROM orders 
      WHERE session_id = ? 
      ORDER BY created_at DESC
    `, [req.params.sessionId])
    
    res.json(orders)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

// Get order detail by order ID
router.get('/detail/:orderId', async (req, res) => {
  try {
    const [orders] = await pool.query('SELECT * FROM orders WHERE id = ?', [req.params.orderId])
    
    if (orders.length === 0) {
      return res.status(404).json({ error: 'Order not found' })
    }
    
    const [items] = await pool.query('SELECT * FROM order_items WHERE order_id = ?', [req.params.orderId])
    
    res.json({
      order: orders[0],
      items
    })
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

export default router
