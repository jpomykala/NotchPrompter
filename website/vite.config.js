import { defineConfig } from 'vite'
import { readFileSync } from 'fs'
import { resolve } from 'path'

const pages = [
  'teleprompter-for-video-calls',
  'teleprompter-for-youtube',
  'teleprompter-for-presentations',
  'how-to-use-a-teleprompter',
  'free-teleprompter-for-mac',
]

// Replaces <!-- include:name --> with the contents of partials/name.html
function htmlPartials() {
  return {
    name: 'html-partials',
    transformIndexHtml: {
      order: 'pre',
      handler: (html) =>
        html.replace(/<!--\s*include:([\w-]+)\s*-->/g, (_, name) =>
          readFileSync(resolve(import.meta.dirname, 'partials', `${name}.html`), 'utf-8')),
    },
  }
}

export default defineConfig({
  base: '/',
  plugins: [htmlPartials()],
  build: {
    // GitHub Pages serves the site from /docs
    outDir: '../docs',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: resolve(import.meta.dirname, 'index.html'),
        'privacy-policy': resolve(import.meta.dirname, 'privacy-policy.html'),
        404: resolve(import.meta.dirname, '404.html'),
        ...Object.fromEntries(pages.map((page) => [page, resolve(import.meta.dirname, page, 'index.html')])),
      },
    },
  },
})
