# E-Commerce Application

Simple e-commerce website for AWS Three-Tier Architecture demo.

## Tech Stack

**Frontend:**
- Vite + React 18
- React Router for navigation
- Axios for API calls
- CSS Modules for styling

**Backend:**
- Node.js + Express
- MySQL (RDS connection)
- RESTful API
- CORS enabled

## Structure

```
ecommerce-app/
├── frontend/          # React + Vite frontend
│   ├── src/
│   │   ├── components/   # Reusable components
│   │   ├── pages/        # Page components
│   │   ├── services/     # API service layer
│   │   └── App.jsx       # Main app component
│   ├── package.json
│   └── vite.config.js
│
└── backend/           # Node.js + Express API
    ├── src/
    │   ├── routes/       # API routes
    │   ├── controllers/  # Business logic
    │   ├── models/       # Database models
    │   └── config/       # Database config
    ├── package.json
    └── server.js
```

## Features

- 🛍️ Product catalog with categories
- 🛒 Shopping cart
- 💳 Checkout process
- 📦 Order management
- 🔍 Product search
- 📱 Responsive design

## Development

### Frontend
```bash
cd frontend
npm install
npm run dev        # http://localhost:5173
```

### Backend
```bash
cd backend
npm install
npm run dev        # http://localhost:3000
```

## Deployment to AWS

1. **Build frontend:**
   ```bash
   cd frontend
   npm run build
   # Deploy dist/ to Web tier (Nginx serves static files)
   ```

2. **Deploy backend:**
   ```bash
   cd backend
   # Deploy to App tier (Node.js API behind Apache proxy)
   ```

3. **Database:**
   - RDS MySQL already configured
   - Schema auto-created on first run

## Environment Variables

**Backend (.env):**
```
DB_HOST=<rds-endpoint>
DB_USER=admin
DB_PASSWORD=<password>
DB_NAME=ecommerce
PORT=3000
```

**Frontend (.env):**
```
VITE_API_URL=http://<internal-alb-dns>
```
