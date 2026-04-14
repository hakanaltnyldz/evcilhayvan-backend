import { BrowserRouter, Navigate, Outlet, Route, Routes } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'
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
import Vets from './pages/Vets.jsx'
import VetClaims from './pages/VetClaims.jsx'
import SellerApplications from './pages/SellerApplications.jsx'
import AuditLogs from './pages/AuditLogs.jsx'
import SellerDashboard from './pages/seller/SellerDashboard.jsx'
import SellerProducts from './pages/seller/SellerProducts.jsx'
import SellerOrders from './pages/seller/SellerOrders.jsx'
import SellerCoupons from './pages/seller/SellerCoupons.jsx'
import SellerAnalytics from './pages/seller/SellerAnalytics.jsx'
import SellerStoreProfile from './pages/seller/SellerStoreProfile.jsx'
import { getDefaultRouteForRole, getSessionRole, getSessionToken, isAllowedRole } from './lib/session.js'

function RequireAuth() {
  return getSessionToken() ? <Outlet /> : <Navigate to="/login" replace />
}

function RequireRole({ allowedRoles }) {
  const role = getSessionRole()
  return isAllowedRole(role, allowedRoles)
    ? <Outlet />
    : <Navigate to={getDefaultRouteForRole(role)} replace />
}

function HomeRedirect() {
  return <Navigate to={getDefaultRouteForRole(getSessionRole())} replace />
}

export default function App() {
  return (
    <BrowserRouter>
      <Toaster
        position="top-right"
        toastOptions={{
          duration: 3500,
          style: {
            background: '#0f172a',
            color: '#f8fafc',
            borderRadius: '16px',
            fontSize: '14px',
            boxShadow: '0 20px 40px rgba(15, 23, 42, 0.18)',
          },
        }}
      />
      <Routes>
        <Route path="/login" element={<Login />} />

        <Route element={<RequireAuth />}>
          <Route element={<Layout />}>
            <Route index element={<HomeRedirect />} />

            <Route element={<RequireRole allowedRoles={['admin']} />}>
              <Route path="dashboard" element={<Dashboard />} />
              <Route path="users" element={<Users />} />
              <Route path="pets" element={<Pets />} />
              <Route path="reports" element={<Reports />} />
              <Route path="orders" element={<Orders />} />
              <Route path="posts" element={<Posts />} />
              <Route path="coupons" element={<Coupons />} />
              <Route path="support" element={<Support />} />
              <Route path="sitters" element={<Sitters />} />
              <Route path="vets" element={<Vets />} />
              <Route path="vet-claims" element={<VetClaims />} />
              <Route path="seller-applications" element={<SellerApplications />} />
              <Route path="audit-logs" element={<AuditLogs />} />
            </Route>

            <Route element={<RequireRole allowedRoles={['seller']} />}>
              <Route path="seller" element={<SellerDashboard />} />
              <Route path="seller/products" element={<SellerProducts />} />
              <Route path="seller/orders" element={<SellerOrders />} />
              <Route path="seller/coupons" element={<SellerCoupons />} />
              <Route path="seller/analytics" element={<SellerAnalytics />} />
              <Route path="seller/store-profile" element={<SellerStoreProfile />} />
            </Route>
          </Route>
        </Route>

        <Route path="*" element={<HomeRedirect />} />
      </Routes>
    </BrowserRouter>
  )
}
