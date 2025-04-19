declare module 'vite-plugin-pwa' {
  // Generic fallback types to satisfy TS until upstream types are installed
  export interface VitePWAOptions {
    [key: string]: any;
  }
  export function VitePWA(options?: VitePWAOptions): any;
  export default VitePWA;
} 