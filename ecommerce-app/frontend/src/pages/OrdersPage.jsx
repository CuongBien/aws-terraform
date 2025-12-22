import React, { useState, useEffect } from 'react'
import { useCart } from '../context/CartContext'
import * as api from '../services/api'
import './OrdersPage.css'

const OrdersPage = () => {
  const { sessionId } = useCart()
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadOrders()
  }, [])

  const loadOrders = async () => {
    try {
      const { data } = await api.getOrders(sessionId)
      setOrders(data)
    } catch (error) {
      console.error('Failed to load orders:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) return <div className="loading container">Loading orders...</div>

  if (orders.length === 0) {
    return (
      <div className="empty-orders container">
        <div className="empty-orders-content">
          <span className="empty-orders-icon">📦</span>
          <h2>No orders yet</h2>
          <p>Start shopping to see your orders here</p>
          <a href="/" className="btn btn-primary">Start Shopping</a>
        </div>
      </div>
    )
  }

  const getStatusBadge = (status) => {
    const badges = {
      pending: 'badge-warning',
      processing: 'badge-primary',
      shipped: 'badge-primary',
      delivered: 'badge-success',
      cancelled: 'badge-danger'
    }
    return badges[status] || 'badge-primary'
  }

  return (
    <div className="orders-page container">
      <h1>My Orders</h1>
      
      <div className="orders-list">
        {orders.map(order => (
          <div key={order.id} className="order-card">
            <div className="order-header">
              <div>
                <h3>Order #{order.id}</h3>
                <p className="order-date">
                  {new Date(order.created_at).toLocaleDateString('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                  })}
                </p>
              </div>
              <span className={`badge ${getStatusBadge(order.status)}`}>
                {order.status.toUpperCase()}
              </span>
            </div>
            
            <div className="order-info">
              <div className="info-row">
                <span>Customer:</span>
                <span>{order.customer_name}</span>
              </div>
              <div className="info-row">
                <span>Email:</span>
                <span>{order.email}</span>
              </div>
              <div className="info-row">
                <span>Phone:</span>
                <span>{order.phone}</span>
              </div>
              <div className="info-row">
                <span>Shipping Address:</span>
                <span>{order.address}, {order.city} {order.zip_code}</span>
              </div>
              <div className="info-row">
                <span>Payment Method:</span>
                <span>{order.payment_method.replace('_', ' ').toUpperCase()}</span>
              </div>
            </div>
            
            <div className="order-total">
              <span>Total Amount:</span>
              <span className="total-price">${parseFloat(order.total_amount).toFixed(2)}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

export default OrdersPage
