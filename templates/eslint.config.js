// Canonical ESLint flat config for chrysa TypeScript repos (standards/rules/frontend.md).
// Copy it to the repo root, then install the dev dependencies with pnpm:
//   pnpm add -D eslint @eslint/js typescript-eslint globals typescript@^6
// typescript-eslint 8 does not support TypeScript 7 yet: keep TypeScript on 6.x.
// It replaces the deprecated pre-commit-tools detectors (DEPRECATIONS.md):
//   console-log/console-debug/console-table/no-console-warn/react-console-error -> no-console
//   ts-unreachable-code -> no-unreachable (+ tsc allowUnreachableCode: false)
//   any usage -> @typescript-eslint/no-explicit-any
// Run it through pnpm in CI or pre-push (`pnpm exec eslint .`), not through a
// mirrors-eslint pre-commit hook: the mirror cannot resolve repo-local plugins.
import js from "@eslint/js";
import globals from "globals";
import tseslint from "typescript-eslint";

export default tseslint.config(
  { ignores: ["dist", "build", "coverage", "node_modules", "**/*.gen.ts"] },
  {
    files: ["**/*.{ts,tsx,mts,cts}"],
    extends: [js.configs.recommended, ...tseslint.configs.strictTypeChecked],
    languageOptions: {
      ecmaVersion: 2022,
      globals: { ...globals.browser, ...globals.node },
      parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname },
    },
    rules: {
      "no-console": "error",
      "no-unreachable": "error",
      "@typescript-eslint/no-explicit-any": "error",
      // chrysa standard (code-quality.md): prefer declarations, cap nested callbacks.
      "func-style": ["error", "declaration"],
      "max-nested-callbacks": ["error", 2],
      complexity: ["error", 10],
    },
  },
  {
    // describe > it > waitFor is an inherent 3-level nesting in tests.
    files: ["**/*.test.{ts,tsx}", "**/test/**", "**/tests/**"],
    rules: { "max-nested-callbacks": ["error", 4] },
  },
  {
    files: ["**/*.{js,mjs,cjs}"],
    extends: [js.configs.recommended, tseslint.configs.disableTypeChecked],
    languageOptions: { globals: globals.node },
  },
);
