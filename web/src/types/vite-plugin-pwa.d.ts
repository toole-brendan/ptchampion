declare module 'vite-plugin-pwa' {
  // Generic fallback types to satisfy TS until upstream types are installed
  export interface VitePWAOptions {
    [key: string]: unknown;
  }
  export function VitePWA(options?: VitePWAOptions): unknown;
  export default VitePWA;
} 