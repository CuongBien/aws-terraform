import React from 'react'
import { Link } from 'react-router-dom'
import { useCart } from '../context/CartContext'
import './Header.css'

const Header = () => {
  const { getCartCount } = useCart()
  const cartCount = getCartCount()

  return (
    <header className="header">
      <div className="container">
        <div className="header-content">
          <Link to="/" className="logo">
            <span className="logo-icon">🛍️</span>
            <span className="logo-text">TechStore</span>
          </Link>

          <nav className="nav">
            <Link to="/" className="nav-link">Home</Link>
            <Link to="/orders" className="nav-link">My Orders</Link>
            <Link to="/cart" className="nav-link cart-link">
              <span>🛒 Cart</span>
              {cartCount > 0 && (
                <span className="cart-badge">{cartCount}</span>
              )}
            </Link>
          </nav>
        </div>
      </div>
    </header>
  )
}

export default Header
