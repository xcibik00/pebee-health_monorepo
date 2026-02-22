import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Pebee Health',
  description: 'Pebee Health platform',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}): React.JSX.Element {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
