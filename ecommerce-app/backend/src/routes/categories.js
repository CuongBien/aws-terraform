import express from 'express'
import pool from '../config/database.js'

const router = express.Router()

// Get all categories
router.get('/', async (req, res) => {
  try {
    const [categories] = await pool.query(`
      SELECT DISTINCT category as id, category as name 
      FROM products 
      ORDER BY category
    `)
    
    res.json(categories)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

export default router
