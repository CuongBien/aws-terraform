// File: ecommerce-app/backend/src/config/database.js
import mysql from 'mysql2/promise'
import dotenv from 'dotenv'

dotenv.config()

const DB_NAME = process.env.DB_NAME || 'ecommerce'

// Connection config WITHOUT database (để tạo database)
const baseConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'pbl4-123456',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
}

// Connection config WITH database (sau khi đã tạo)
const dbConfig = {
  ...baseConfig,
  database: DB_NAME
}

// Create database if not exists
export async function createDatabaseIfNotExists() {
  const connection = await mysql.createConnection(baseConfig)
  try {
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\``)
    console.log(`✓ Database '${DB_NAME}' ready`)
  } catch (error) {
    console.error('✗ Failed to create database:', error.message)
    throw error
  } finally {
    await connection.end()
  }
}

// Create connection pool (with database)
export const pool = mysql.createPool(dbConfig)

// Test connection
export async function testConnection() {
  try {
    const connection = await pool.getConnection()
    console.log('✓ Database connected successfully')
    connection.release()
    return true
  } catch (error) {
    console.error('✗ Database connection failed:', error.message)
    return false
  }
}

// Initialize database schema
export async function initDatabase() {
  try {
    // Step 1: Create database
    await createDatabaseIfNotExists()
    
    // Step 2: Connect to database
    await testConnection()
    
    // Step 3: Create tables
    await pool.query(`
      CREATE TABLE IF NOT EXISTS products (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        price DECIMAL(10, 2) NOT NULL,
        category VARCHAR(100) NOT NULL,
        stock INT DEFAULT 0,
        image_url VARCHAR(500),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `)
    
    await pool.query(`
      CREATE TABLE IF NOT EXISTS cart (
        id INT AUTO_INCREMENT PRIMARY KEY,
        session_id VARCHAR(255) NOT NULL,
        product_id INT NOT NULL,
        quantity INT DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
        UNIQUE KEY unique_cart_item (session_id, product_id)
      )
    `)
    
    await pool.query(`
      CREATE TABLE IF NOT EXISTS orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        session_id VARCHAR(255) NOT NULL,
        customer_name VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL,
        phone VARCHAR(50) NOT NULL,
        address TEXT NOT NULL,
        city VARCHAR(100) NOT NULL,
        zip_code VARCHAR(20) NOT NULL,
        payment_method VARCHAR(50) NOT NULL,
        total_amount DECIMAL(10, 2) NOT NULL,
        status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `)
    
    await pool.query(`
      CREATE TABLE IF NOT EXISTS order_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id INT NOT NULL,
        product_id INT NOT NULL,
        quantity INT NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    `)
    
    console.log('✓ Database schema initialized')
    
    // Insert sample products if table is empty
    const [rows] = await pool.query('SELECT COUNT(*) as count FROM products')
    if (rows[0].count === 0) {
      await insertSampleData()
    }
    
  } catch (error) {
    console.error('Database initialization error:', error)
    throw error
  }
}

// Insert sample product data
async function insertSampleData() {
  const sampleProducts = [
    ['Laptop Dell XPS 13', 'Powerful ultrabook with Intel i7', 1299.99, 'Electronics', 10, 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=500'],
    ['iPhone 14 Pro', 'Latest Apple smartphone', 999.99, 'Electronics', 15, 'https://images.unsplash.com/photo-1678685888221-cda773a3dcdb?w=500'],
    ['Sony WH-1000XM5', 'Noise cancelling headphones', 349.99, 'Electronics', 20, 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?w=500'],
    ['Samsung Galaxy Watch', 'Smart fitness watch', 299.99, 'Electronics', 12, 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=500'],
    ['Nike Air Max 90', 'Classic sneakers', 129.99, 'Fashion', 25, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=500'],
    ['Adidas Ultraboost', 'Running shoes', 179.99, 'Fashion', 18, 'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=500'],
    ['Leather Backpack', 'Stylish laptop backpack', 89.99, 'Fashion', 30, 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500'],
    ['Coffee Maker Pro', 'Automatic espresso machine', 449.99, 'Home', 8, 'https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?w=500'],
    ['Robot Vacuum', 'Smart home cleaning', 299.99, 'Home', 14, 'https://images.unsplash.com/photo-1558317374-067fb5f30001?w=500'],
    ['Air Purifier', 'HEPA filter air cleaner', 199.99, 'Home', 16, 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=500']
  ]
  
  await pool.query(
    'INSERT INTO products (name, description, price, category, stock, image_url) VALUES ?',
    [sampleProducts]
  )
  
  console.log('✓ Sample products inserted')
}

export default pool