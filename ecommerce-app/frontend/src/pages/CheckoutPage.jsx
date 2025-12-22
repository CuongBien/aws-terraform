import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useCart } from '../context/CartContext'
import * as api from '../services/api'
import './CheckoutPage.css'

const CheckoutPage = () => {
  const { cart, sessionId, getCartTotal, clearCart } = useCart()
  const navigate = useNavigate()
  const [submitting, setSubmitting] = useState(false)
  const [formData, setFormData] = useState({
    customerName: '',
    email: '',
    phone: '',
    address: '',
    city: '',
    zipCode: '',
    paymentMethod: 'credit_card'
  })

  if (cart.length === 0) {
    navigate('/cart')
    return null
  }

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    })
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    
    try {
      setSubmitting(true)
      
      const orderData = {
        ...formData,
        sessionId,
        items: cart.map(item => ({
          productId: item.product_id,
          quantity: item.quantity,
          price: item.price
        })),
        totalAmount: getCartTotal()
      }
      
      const { data } = await api.createOrder(orderData)
      
      await clearCart()
      
      alert(`Order placed successfully! Order ID: ${data.orderId}`)
      navigate('/orders')
    } catch (error) {
      alert('Failed to place order. Please try again.')
      console.error(error)
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="checkout-page container">
      <h1>Checkout</h1>
      
      <div className="checkout-content">
        <form className="checkout-form" onSubmit={handleSubmit}>
          <div className="form-section">
            <h2>Contact Information</h2>
            
            <div className="form-group">
              <label>Full Name *</label>
              <input
                type="text"
                name="customerName"
                value={formData.customerName}
                onChange={handleChange}
                required
              />
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label>Email *</label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Phone *</label>
                <input
                  type="tel"
                  name="phone"
                  value={formData.phone}
                  onChange={handleChange}
                  required
                />
              </div>
            </div>
          </div>
          
          <div className="form-section">
            <h2>Shipping Address</h2>
            
            <div className="form-group">
              <label>Address *</label>
              <input
                type="text"
                name="address"
                value={formData.address}
                onChange={handleChange}
                required
              />
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label>City *</label>
                <input
                  type="text"
                  name="city"
                  value={formData.city}
                  onChange={handleChange}
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Zip Code *</label>
                <input
                  type="text"
                  name="zipCode"
                  value={formData.zipCode}
                  onChange={handleChange}
                  required
                />
              </div>
            </div>
          </div>
          
          <div className="form-section">
            <h2>Payment Method</h2>
            
            <div className="payment-methods">
              <label className="payment-option">
                <input
                  type="radio"
                  name="paymentMethod"
                  value="credit_card"
                  checked={formData.paymentMethod === 'credit_card'}
                  onChange={handleChange}
                />
                <span>Credit Card</span>
              </label>
              
              <label className="payment-option">
                <input
                  type="radio"
                  name="paymentMethod"
                  value="paypal"
                  checked={formData.paymentMethod === 'paypal'}
                  onChange={handleChange}
                />
                <span>PayPal</span>
              </label>
              
              <label className="payment-option">
                <input
                  type="radio"
                  name="paymentMethod"
                  value="cash_on_delivery"
                  checked={formData.paymentMethod === 'cash_on_delivery'}
                  onChange={handleChange}
                />
                <span>Cash on Delivery</span>
              </label>
            </div>
          </div>
          
          <button 
            type="submit" 
            className="btn btn-primary btn-block"
            disabled={submitting}
          >
            {submitting ? 'Processing...' : `Place Order - $${parseFloat(getCartTotal()).toFixed(2)}`}
          </button>
        </form>
        
        <div className="order-summary">
          <h2>Order Summary</h2>
          
          <div className="summary-items">
            {cart.map(item => (
              <div key={item.product_id} className="summary-item">
                <img src={item.image_url || '/placeholder.png'} alt={item.name} />
                <div className="summary-item-info">
                  <h4>{item.name}</h4>
                  <p>Qty: {item.quantity}</p>
                </div>
                <span className="summary-item-price">
                  ${(parseFloat(item.price) * item.quantity).toFixed(2)}
                </span>
              </div>
            ))}
          </div>
          
          <div className="summary-totals">
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
          </div>
        </div>
      </div>
    </div>
  )
}

export default CheckoutPage
