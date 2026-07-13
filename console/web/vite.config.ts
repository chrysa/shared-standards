import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "node:path";

// Dev proxies /api to the local FastAPI backend; prod build lands in web_dist/
// so the backend can serve the SPA from a single process.
export default defineConfig({
  plugins: [react()],
  resolve: { alias: { "@": path.resolve(__dirname, "src") } },
  server: {
    port: 5173,
    proxy: { "/api": "http://127.0.0.1:8765" },
  },
  build: { outDir: path.resolve(__dirname, "../standards_console/web_dist"), emptyOutDir: true },
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: "./src/test/setup.ts",
    // Coverage for SonarCloud (Phase 2, #183): `npm run test:cov` emits lcov at
    // coverage/lcov.info — feed it to Sonar via sonar.javascript.lcov.reportPaths
    // once sonar-scan-python accepts a JS lcov input.
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
      reportsDirectory: "coverage",
      include: ["src/**/*.{ts,tsx}"],
      exclude: ["src/**/*.test.{ts,tsx}", "src/test/**", "src/**/*.d.ts"],
    },
  },
});
