import {
  ArchiveBoxIcon,
  ChartBarIcon,
  ChatBubbleBottomCenterTextIcon,
  ClipboardDocumentListIcon,
  Cog6ToothIcon,
  CubeIcon,
  DocumentMagnifyingGlassIcon,
  FlagIcon,
  HomeIcon,
  QueueListIcon,
  ReceiptPercentIcon,
  ArrowUturnLeftIcon,
  ShoppingBagIcon,
  ShoppingCartIcon,
  ShieldCheckIcon,
  ShieldExclamationIcon,
  UsersIcon,
} from '@heroicons/react/24/outline'

export const adminNavigation = [
  {
    title: 'Genel',
    items: [
      { to: '/dashboard', label: 'Genel Bakis', icon: HomeIcon },
      { to: '/users', label: 'Kullanicilar', icon: UsersIcon },
      { to: '/pets', label: 'Ilanlar', icon: QueueListIcon },
      { to: '/orders', label: 'Siparisler', icon: ShoppingCartIcon },
      { to: '/returns', label: 'Iadeler', icon: ArrowUturnLeftIcon },
      { to: '/coupons', label: 'Kuponlar', icon: ReceiptPercentIcon },
      { to: '/platform-settings', label: 'Platform Ayarlari', icon: Cog6ToothIcon },
    ],
  },
  {
    title: 'Moderasyon',
    items: [
      { to: '/moderation-queue', label: 'Moderasyon Kuyrugu', icon: ShieldExclamationIcon },
      { to: '/reports', label: 'Sikayetler', icon: FlagIcon },
      { to: '/posts', label: 'Gonderiler', icon: DocumentMagnifyingGlassIcon },
      { to: '/support', label: 'Destek', icon: ChatBubbleBottomCenterTextIcon },
    ],
  },
  {
    title: 'Partnerler',
    items: [
      { to: '/sitters', label: 'Bakicilar', icon: ShieldCheckIcon },
      { to: '/vets', label: 'Veterinerler', icon: ShieldCheckIcon },
      { to: '/vet-claims', label: 'Klinik Talepleri', icon: ClipboardDocumentListIcon },
      { to: '/seller-applications', label: 'Satici Basvurulari', icon: ShoppingBagIcon },
      { to: '/audit-logs', label: 'Audit Loglari', icon: ArchiveBoxIcon },
    ],
  },
]

export const sellerNavigation = [
  {
    title: 'Magaza',
    items: [
      { to: '/seller', label: 'Dashboard', icon: HomeIcon },
      { to: '/seller/products', label: 'Urunler', icon: CubeIcon },
      { to: '/seller/orders', label: 'Siparisler', icon: ShoppingCartIcon },
      { to: '/seller/coupons', label: 'Kuponlar', icon: ReceiptPercentIcon },
      { to: '/seller/analytics', label: 'Analitik', icon: ChartBarIcon },
      { to: '/seller/store-profile', label: 'Magaza Profili', icon: ShoppingBagIcon },
    ],
  },
]

export function getNavigationByRole(role) {
  return role === 'seller' ? sellerNavigation : adminNavigation
}

function flattenNavigation(role) {
  return getNavigationByRole(role).flatMap((section) => section.items)
}

export function getPageMeta(pathname, role) {
  const items = flattenNavigation(role)
    .slice()
    .sort((a, b) => b.to.length - a.to.length)

  const exactMatch = items.find((item) => item.to === pathname)
  if (exactMatch) return exactMatch

  const nestedMatch = items.find((item) => item.to !== '/' && pathname.startsWith(`${item.to}/`))
  return nestedMatch || items[0]
}
