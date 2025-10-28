/* eslint-disable import/no-extraneous-dependencies */

import * as path from 'path';

import vue from '@vitejs/plugin-vue';
import analyze from 'rollup-plugin-analyzer';
import {defineConfig} from 'vite';

// https://vitejs.dev/config/
export default defineConfig(({ command }) => ({
  base: command === 'serve' ? '' : '/build/',
  publicDir: 'fake_dir_so_nothing_gets_copied',

  resolve: {
    dedupe: ['vue'],

    alias: [
      {
        // allow tsconfig "@" path alias
        find: '@',
        replacement: path.resolve(__dirname, '/resources/js'),
      },
    ],
  },

  optimizeDeps: {
    // optimizing interferes with yalc
    exclude: [],
  },

  build: {
    manifest: true,
    outDir: 'public/build',
    rollupOptions: {
      input: 'resources/js/app.ts',
      plugins: [
        analyze({
          summaryOnly: true,
          limit: 10,
        }),
      ],
    },
  },

  plugins: [
    vue(),
  ],
}));
