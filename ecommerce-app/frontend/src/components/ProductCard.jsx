import React from 'react'
import { Link } from 'react-router-dom'
import { useCart } from '../context/CartContext'
import './ProductCard.css'

const ProductCard = ({ product }) => {
  const { addToCart } = useCart()
  const [adding, setAdding] = React.useState(false)

  const handleAddToCart = async (e) => {
    e.preventDefault()
    e.stopPropagation()
    
    try {
      setAdding(true)
      await addToCart(product, 1)
      alert('Added to cart!')
    } catch (error) {
      alert('Failed to add to cart')
    } finally {
      setAdding(false)
    }
  }

  return (
    <Link to={`/product/${product.id}`} className="product-card">
      <div className="product-image">
        <img src={product.image_url || '/placeholder.png'} alt={product.name} />
        {product.stock < 10 && product.stock > 0 && (
          <span className="badge badge-warning">Only {product.stock} left</span>
        )}
        {product.stock === 0 && (
          <span className="badge badge-danger">Out of Stock</span>
        )}
      </div>
      
      <div className="product-info">
        <span className="product-category">{product.category}</span>
        <h3 className="product-name">{product.name}</h3>
        <p className="product-description">{product.description}</p>
        
        <div className="product-footer">
          <span className="product-price">${parseFloat(product.price).toFixed(2)}</span>
          <button 
            className="btn btn-primary btn-sm"
            onClick={handleAddToCart}
            disabled={adding || product.stock === 0}
          >
            {adding ? 'Adding...' : 'Add to Cart'}
          </button>
        </div>
      </div>
    </Link>
  )
}

export default ProductCard
