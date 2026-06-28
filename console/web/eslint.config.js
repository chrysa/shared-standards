import js from "@eslint/js";
import globals from "globals";
import tseslint from "typescript-eslint";

export default tseslint.config(
  { ignores: ["dist", "../standards_console/web_dist"] },
  {
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    files: ["**/*.{ts,tsx}"],
    languageOptions: { ecmaVersion: 2022, globals: globals.browser },
    rules: {
      // chrysa standard: prefer declarations, cap nested callbacks.
      "max-nested-callbacks": ["error", 2],
    },
  },
  {
    // describe > it > waitFor is an inherent 3-level nesting in tests.
    files: ["**/*.test.{ts,tsx}", "**/test/**"],
    rules: { "max-nested-callbacks": ["error", 4] },
  },
);
