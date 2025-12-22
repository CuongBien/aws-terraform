import React from 'react'
import { useCart } from '../context/CartContext'
import { Link } from 'react-router-dom'
import './CartPage.css'

const CartPage = () => {
  const { cart, loading, updateQuantity, removeFromCart, getCartTotal } = useCart()

  if (loading) return <div className="loading container">Loading cart...</div>

  if (cart.length === 0) {
    return (
      <div className="empty-cart container">
        <div className="empty-cart-content">
          <span className="empty-cart-icon">🛒</span>
          <h2>Your cart is empty</h2>
          <p>Add some products to get started</p>
          <Link to="/" className="btn btn-primary">Continue Shopping</Link>
        </div>
      </div>
    )
  }

  return (
    <div className="cart-page container">
      <h1>Shopping Cart</h1>
      
      <div className="cart-content">
        <div className="cart-items">
          {cart.map(item => (
            <div key={item.product_id} className="cart-item">
              <img src={item.image_url || '/placeholder.png'} alt={item.name} />
              
              <div className="cart-item-info">
                <h3>{item.name}</h3>
                <p className="item-category">{item.category}</p>
                <p className="item-price">${parseFloat(item.price).toFixed(2)} each</p>
              </div>
              
              <div className="cart-item-actions">
                <div className="quantity-controls">
                  <button onClick={() => updateQuantity(item.product_id, item.quantity - 1)}>−</button>
                  <span>{item.quantity}</span>
                  <button onClick={() => updateQuantity(item.product_id, item.quantity + 1)}>+</button>
                </div>
                
                <p className="item-total">${(parseFloat(item.price) * item.quantity).toFixed(2)}</p>
                
                <button 
                  className="btn-remove"
                  onClick={() => removeFromCart(item.product_id)}
                >
                  Remove
                </button>
              </div>
            </div>
          ))}
        </div>
        
        <div className="cart-summary">
          <h2>Order Summary</h2>
          
          <div className="summary-row">
            <span>Subtotal:</span>
            <span>${parseFloat(getCartTotal()).toFixed(2)}</span>
          </div>
          
          <div className="summary-row">
            <span>Shipping:</span>
            <span>Free</span>
          </div>
          
          <div className="summary-row summary-total">
            <span>Total:</span>
            <span>${parseFloat(getCartTotal()).toFixed(2)}</span>
          </div>
          
          <Link to="/checkout" className="btn btn-primary btn-block">
            Proceed to Checkout
          </Link>
          
          <Link to="/" className="btn btn-secondary btn-block">
            Continue Shopping
          </Link>
        </div>
      </div>
    </div>
  )
}

export default CartPage
