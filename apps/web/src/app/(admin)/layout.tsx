// Admin route group — all routes here require superadmin authentication.
// Auth enforcement is handled via middleware + backend JWT validation.

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}): React.JSX.Element {
  return <>{children}</>;
}
