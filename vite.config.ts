import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { mime } from 'vite-plugin-mime';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react(), mime()],
  optimizeDeps: {
    exclude: ['lucide-react'],
  },
});
