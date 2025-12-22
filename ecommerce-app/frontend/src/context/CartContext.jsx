import React, { createContext, useContext, useState, useEffect } from 'react'
import * as api from '../services/api'

const CartContext = createContext()

export const useCart = () => {
  const context = useContext(CartContext)
  if (!context) {
    throw new Error('useCart must be used within CartProvider')
  }
  return context
}

export const CartProvider = ({ children }) => {
  const [cart, setCart] = useState([])
  const [loading, setLoading] = useState(false)
  const [sessionId] = useState(() => {
    let id = localStorage.getItem('sessionId')
    if (!id) {
      id = 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9)
      localStorage.setItem('sessionId', id)
    }
    return id
  })

  useEffect(() => {
    loadCart()
  }, [])

  const loadCart = async () => {
    try {
      setLoading(true)
      const { data } = await api.getCart(sessionId)
      setCart(data.items || [])
    } catch (error) {
      console.error('Load cart error:', error)
      setCart([])
    } finally {
      setLoading(false)
    }
  }

  const addToCart = async (product, quantity = 1) => {
    try {
      await api.addToCart(sessionId, product.id, quantity)
      await loadCart()
    } catch (error) {
      console.error('Add to cart error:', error)
      throw error
    }
  }

  const updateQuantity = async (productId, quantity) => {
    try {
      if (quantity <= 0) {
        await removeFromCart(productId)
      } else {
        await api.updateCartItem(sessionId, productId, quantity)
        await loadCart()
      }
    } catch (error) {
      console.error('Update quantity error:', error)
      throw error
    }
  }

  const removeFromCart = async (productId) => {
    try {
      await api.removeFromCart(sessionId, productId)
      await loadCart()
    } catch (error) {
      console.error('Remove from cart error:', error)
      throw error
    }
  }

  const clearCart = async () => {
    try {
      await api.clearCart(sessionId)
      setCart([])
    } catch (error) {
      console.error('Clear cart error:', error)
      throw error
    }
  }

  const getCartTotal = () => {
    return cart.reduce((total, item) => total + (parseFloat(item.price) * item.quantity), 0)
  }

  const getCartCount = () => {
    return cart.reduce((count, item) => count + item.quantity, 0)
  }

  return (
    <CartContext.Provider value={{
      cart,
      loading,
      sessionId,
      addToCart,
      updateQuantity,
      removeFromCart,
      clearCart,
      getCartTotal,
      getCartCount,
      loadCart
    }}>
      {children}
    </CartContext.Provider>
  )
}
