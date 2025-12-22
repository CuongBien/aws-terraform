import React, { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useCart } from '../context/CartContext'
import * as api from '../services/api'
import './ProductPage.css'

const ProductPage = () => {
  const { id } = useParams()
  const navigate = useNavigate()
  const { addToCart } = useCart()
  const [product, setProduct] = useState(null)
  const [quantity, setQuantity] = useState(1)
  const [loading, setLoading] = useState(true)
  const [adding, setAdding] = useState(false)

  useEffect(() => {
    loadProduct()
  }, [id])

  const loadProduct = async () => {
    try {
      const { data } = await api.getProduct(id)
      setProduct(data)
    } catch (error) {
      console.error('Failed to load product:', error)
      alert('Product not found')
      navigate('/')
    } finally {
      setLoading(false)
    }
  }

  const handleAddToCart = async () => {
    try {
      setAdding(true)
      await addToCart(product, quantity)
      alert('Added to cart!')
    } catch (error) {
      alert('Failed to add to cart')
    } finally {
      setAdding(false)
    }
  }

  if (loading) return <div className="loading container">Loading product...</div>
  if (!product) return null

  return (
    <div className="product-page container">
      <button className="btn-back" onClick={() => navigate(-1)}>
        ← Back
      </button>
      
      <div className="product-detail">
        <div className="product-image-large">
          <img src={product.image_url || '/placeholder.png'} alt={product.name} />
        </div>
        
        <div className="product-info-large">
          <span className="product-category-large">{product.category}</span>
          <h1>{product.name}</h1>
          <p className="product-description-large">{product.description}</p>
          
          <div className="product-price-large">${parseFloat(product.price).toFixed(2)}</div>
          
          <div className="product-stock">
            {product.stock > 0 ? (
              <>
                <span className="stock-available">✓ In Stock</span>
                <span className="stock-count">({product.stock} available)</span>
              </>
            ) : (
              <span className="stock-out">Out of Stock</span>
            )}
          </div>
          
          <div className="product-actions">
            <div className="quantity-selector">
              <label>Quantity:</label>
              <div className="quantity-controls-large">
                <button 
                  onClick={() => setQuantity(Math.max(1, quantity - 1))}
                  disabled={quantity <= 1}
                >
                  −
                </button>
                <input 
                  type="number" 
                  value={quantity}
                  onChange={(e) => setQuantity(Math.max(1, parseInt(e.target.value) || 1))}
                  min="1"
                  max={product.stock}
                />
                <button 
                  onClick={() => setQuantity(Math.min(product.stock, quantity + 1))}
                  disabled={quantity >= product.stock}
                >
                  +
                </button>
              </div>
            </div>
            
            <button 
              className="btn btn-primary btn-large"
              onClick={handleAddToCart}
              disabled={adding || product.stock === 0}
            >
              {adding ? 'Adding to Cart...' : 'Add to Cart'}
            </button>
          </div>
          
          <div className="product-features">
            <h3>Features:</h3>
            <ul>
              <li>✓ Free shipping on orders over $50</li>
              <li>✓ 30-day return policy</li>
              <li>✓ 1-year warranty</li>
              <li>✓ 24/7 customer support</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  )
}

export default ProductPage
