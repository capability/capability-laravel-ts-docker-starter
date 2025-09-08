import { defineConfig } from 'vite';

function parseSourceMap(value?: string): boolean | 'hidden' | 'inline' | false {
  if (!value) return false;
  const v = value.toLowerCase();
  if (v === 'true') return true;
  if (v === 'false') return false;
  if (v === 'hidden') return 'hidden';
  if (v === 'inline') return 'inline';
  return false;
}

export default defineConfig(({ mode }) => {
  const sm = mode === 'production'
    ? parseSourceMap(process.env.SOURCEMAPS)
    : true;

  return {
    build: {
      sourcemap: sm,
    },
    server: {
      host: '0.0.0.0',
      // Required for HMR over TLS when proxied through Caddy
      hmr: {
        host: process.env.FRONTEND_HOST || 'ui.${process.env.PROJECT_SLUG}.test',
        protocol: 'wss',
        clientPort: 443,
      },
    },
  };
});

