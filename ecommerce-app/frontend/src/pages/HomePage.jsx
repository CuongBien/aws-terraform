import React, { useState, useEffect } from 'react'
import ProductCard from '../components/ProductCard'
import * as api from '../services/api'
import './HomePage.css'

const HomePage = () => {
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [selectedCategory, setSelectedCategory] = useState('all')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    loadData()
  }, [])

  useEffect(() => {
    loadProducts()
  }, [selectedCategory])

  const loadData = async () => {
    try {
      const [productsRes, categoriesRes] = await Promise.all([
        api.getProducts(),
        api.getCategories()
      ])
      setProducts(productsRes.data)
      setCategories([{ id: 'all', name: 'All Products' }, ...categoriesRes.data])
      setLoading(false)
    } catch (err) {
      setError('Failed to load products')
      setLoading(false)
    }
  }

  const loadProducts = async () => {
    try {
      setLoading(true)
      const { data } = selectedCategory === 'all' 
        ? await api.getProducts()
        : await api.getProductsByCategory(selectedCategory)
      setProducts(data)
    } catch (err) {
      setError('Failed to load products')
    } finally {
      setLoading(false)
    }
  }

  if (loading) return <div className="loading container">Loading products...</div>
  if (error) return <div className="error container">{error}</div>

  return (
    <div className="home-page container">
      <div className="hero">
        <h1>Welcome to TechStore</h1>
        <p>Discover the latest tech products with AWS-powered infrastructure</p>
      </div>

      <div className="category-filter">
        {categories.map(cat => (
          <button
            key={cat.id}
            className={`category-btn ${selectedCategory === cat.id ? 'active' : ''}`}
            onClick={() => setSelectedCategory(cat.id)}
          >
            {cat.name}
          </button>
        ))}
      </div>

      <div className="products-section">
        <h2>
          {selectedCategory === 'all' ? 'All Products' : 
           categories.find(c => c.id === selectedCategory)?.name}
        </h2>
        
        {products.length === 0 ? (
          <p className="no-products">No products found in this category</p>
        ) : (
          <div className="products-grid">
            {products.map(product => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default HomePage
