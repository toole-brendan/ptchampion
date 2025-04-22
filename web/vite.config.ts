import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
// Using dynamic imports to fix TS errors for missing module declarations
import type { VitePWAOptions } from 'vite-plugin-pwa';

// https://vitejs.dev/config/
export default defineConfig(async () => {
  // Dynamically import plugins to avoid TS errors
  const { VitePWA } = await import('vite-plugin-pwa');
  const compression = await import('vite-plugin-compression');

  const pwaOptions: Partial<VitePWAOptions> = {
    registerType: 'autoUpdate',
    workbox: {
      globPatterns: ['**/*.{js,css,html,ico,png,svg,jpg,jpeg,webp,woff,woff2}'],
      runtimeCaching: [
        {
          urlPattern: /^https:\/\/ptchampion-api-westus\.azurewebsites\.net\/api\/.*/i,
          handler: 'NetworkFirst',
          options: {
            cacheName: 'api-cache',
            expiration: {
              maxEntries: 100,
              maxAgeSeconds: 60 * 60 * 24, // 1 day
            },
            networkTimeoutSeconds: 10,
            cacheableResponse: {
              statuses: [0, 200],
            },
          },
        },
        {
          urlPattern: /^https:\/\/fonts\.googleapis\.com/,
          handler: 'StaleWhileRevalidate',
          options: {
            cacheName: 'google-fonts-stylesheets',
          },
        },
        {
          urlPattern: /^https:\/\/fonts\.gstatic\.com/,
          handler: 'CacheFirst',
          options: {
            cacheName: 'google-fonts-webfonts',
            expiration: {
              maxEntries: 30,
              maxAgeSeconds: 60 * 60 * 24 * 365, // 1 year
            },
            cacheableResponse: {
              statuses: [0, 200],
            },
          },
        },
      ],
    },
    manifest: {
      name: 'PT Champion',
      short_name: 'PTChampion',
      description: 'Track and improve your fitness with PT Champion',
      theme_color: '#1E241E',
      background_color: '#F4F1E6',
      display: 'standalone',
      icons: [
        {
          src: '/icons/icon-72x72.png',
          sizes: '72x72',
          type: 'image/png',
          purpose: 'any maskable',
        },
        {
          src: '/icons/icon-96x96.png',
          sizes: '96x96',
          type: 'image/png',
          purpose: 'any maskable',
        },
        {
          src: '/icons/icon-128x128.png',
          sizes: '128x128',
          type: 'image/png',
          purpose: 'any maskable',
        },
        {
          src: '/icons/icon-144x144.png',
          sizes: '144x144',
          type: 'image/png',
          purpose: 'any maskable',
        },
        {
          src: '/icons/icon-152x152.png',
          sizes: '152x152',
          type: 'image/png',
          purpose: 'any maskable',
        },
        {
          src: '/icons/icon-192x192.png',
          sizes: '192x192',
          type: 'image/png',
          purpose: 'any maskable',
        },
        {
          src: '/icons/icon-384x384.png',
          sizes: '384x384',
          type: 'image/png',
          purpose: 'any maskable',
        },
        {
          src: '/icons/icon-512x512.png',
          sizes: '512x512',
          type: 'image/png',
          purpose: 'any maskable',
        },
      ],
    },
  };

  return {
    plugins: [
      react(),
      compression.default({ algorithm: 'gzip' }), // gzip compression
      compression.default({ algorithm: 'brotliCompress', ext: '.br' }), // brotli compression
      VitePWA(pwaOptions),
    ],
    build: {
      // Enable source maps for debugging
      sourcemap: process.env.NODE_ENV !== 'production',
      // Make chunk sizes more reasonable
      chunkSizeWarningLimit: 1000,
      rollupOptions: {
        output: {
          manualChunks: (id: string) => {
            // More granular control with a function
            if (id.includes('node_modules/react/') || 
                id.includes('node_modules/react-dom/') || 
                id.includes('node_modules/react-router-dom/')) {
              return 'react-vendor';
            }
            
            if (id.includes('node_modules/@radix-ui/')) {
              return 'ui-vendor';
            }
            
            if (id.includes('node_modules/@tanstack/react-query')) {
              return 'query-vendor';
            }
            
            if (id.includes('node_modules/@mediapipe/')) {
              return 'mediapipe-vendor';
            }
            
            return null; // default chunk
          }
        },
      },
    },
    server: {
      port: 3000,
      proxy: {
        '/api': {
          target: 'http://localhost:8080',
          changeOrigin: true,
        },
      },
    },
    preview: {
      port: 3000,
    },
  };
});
