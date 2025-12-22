import React from 'react'
import './Footer.css'

const Footer = () => {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-content">
          <div className="footer-section">
            <h3>TechStore</h3>
            <p>Your trusted e-commerce platform for tech products</p>
          </div>
          
          <div className="footer-section">
            <h4>Quick Links</h4>
            <ul>
              <li><a href="/">Home</a></li>
              <li><a href="/orders">My Orders</a></li>
              <li><a href="/cart">Shopping Cart</a></li>
            </ul>
          </div>
          
          <div className="footer-section">
            <h4>Contact</h4>
            <p>Email: support@techstore.com</p>
            <p>Phone: +1 234 567 8900</p>
          </div>
          
          <div className="footer-section">
            <h4>AWS Architecture</h4>
            <p>Deployed on AWS Three-Tier Infrastructure</p>
            <p>Blue/Green Deployment • High Availability</p>
          </div>
        </div>
        
        <div className="footer-bottom">
          <p>&copy; 2025 TechStore. Demo for AWS Three-Tier Architecture Project.</p>
        </div>
      </div>
    </footer>
  )
}

export default Footer
