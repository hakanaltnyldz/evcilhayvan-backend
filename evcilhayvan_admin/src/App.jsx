import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Layout from './components/Layout.jsx'
import Login from './pages/Login.jsx'
import Dashboard from './pages/Dashboard.jsx'
import Users from './pages/Users.jsx'
import Pets from './pages/Pets.jsx'
import Reports from './pages/Reports.jsx'
import Orders from './pages/Orders.jsx'
import Posts from './pages/Posts.jsx'
import Coupons from './pages/Coupons.jsx'
import Support from './pages/Support.jsx'
import Sitters from './pages/Sitters.jsx'

function PrivateRoute({ children }) {
  const token = localStorage.getItem('admin_token')
  return token ? children : <Navigate to="/login" replace />
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route
          path="/"
          element={
            <PrivateRoute>
              <Layout />
            </PrivateRoute>
          }
        >
          <Route index element={<Dashboard />} />
          <Route path="users" element={<Users />} />
          <Route path="pets" element={<Pets />} />
          <Route path="reports" element={<Reports />} />
          <Route path="orders" element={<Orders />} />
          <Route path="posts" element={<Posts />} />
          <Route path="coupons" element={<Coupons />} />
          <Route path="support" element={<Support />} />
          <Route path="sitters" element={<Sitters />} />
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
