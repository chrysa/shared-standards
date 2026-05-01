# GitHub Copilot Instructions — React 19

<!-- @[claude-sonnet-4] -->

Extends [base.md](base.md). Read base rules first; rules here take precedence where they conflict.

## Bootstrap

All React apps **must** be bootstrapped from `Forge-Stack-Workshop/react-app-generator`.
Never scaffold from `create-react-app`, `vite` directly, or from scratch.

## Project layout

```
src/
  api/          # typed API clients (axios/fetch wrappers, no business logic)
  components/   # shared UI components (pure presentational, no data fetching)
  features/     # feature slices: components + hooks + slice + types colocated
  hooks/        # global custom hooks
  pages/        # route-level components — thin wrappers over features
  store/        # Redux Toolkit store + root reducer
  constants.ts  # app-wide constants (as const)
  types/        # shared TypeScript types
  utils/        # pure utility functions
```

## React 19 specifics

- Use React Compiler if enabled — avoid manual `useMemo`/`useCallback` unless profiling proves need.
- Prefer React 19 `use()` hook for promise resolution over manual `useState`/`useEffect` combos.
- Server Actions: use for form mutations when using Next.js; keep pure for reusability.
- Avoid legacy patterns: class components, `React.FC`, `defaultProps`, string refs.

## State management

- Global server state: React Query (`@tanstack/react-query`). No Redux for server data.
- Global UI state: Redux Toolkit. Use `createSlice`; no hand-written reducers.
- Local state: `useState`/`useReducer`. Prefer local unless clearly needed elsewhere.
- Never put server responses directly in Redux — let React Query own them.

## Component rules

- Prefer function components with explicit `interface Props {}`.
- One component per file; filename matches export name (PascalCase).
- Keep components under 100 lines. Split presentational and container logic.
- Co-locate stories (`.stories.tsx`) and tests (`.test.tsx`) next to the component.
- No business logic in components — delegate to custom hooks or services.

## TypeScript

- `strict: true` — no `any`, no `@ts-ignore` without justification comment.
- Prefer `interface` for objects, `type` for unions/aliases.
- Never use `as` casts at runtime boundaries — use Zod or type guards instead.
- Validate all API responses with a Zod schema before use.

## API integration

- All fetch calls live in `src/api/`; never call `fetch` directly from components.
- Use React Query's `useQuery`/`useMutation` for data fetching — no `useEffect` + `fetch`.
- Handle loading, error, and empty states explicitly in every data-driven component.

## Routing

- Use React Router v6+ with `createBrowserRouter`.
- Route definitions in one file; components loaded lazily with `React.lazy`.
- Guard protected routes with an `AuthGuard` wrapper.

## Styling

- Prefer Tailwind CSS utility classes.
- No inline `style` props except for dynamic computed values.
- Component-scoped CSS modules are acceptable for complex animations.

## Security

- Sanitise all user-generated HTML before rendering (use DOMPurify).
- Never store tokens in `localStorage` — prefer `httpOnly` cookies.
- Validate and encode URL parameters; never interpolate user input into URLs.

## Testing

- Vitest + React Testing Library.
- Test user behaviour, not implementation details.
- Mock API calls with MSW (`@mswjs/msw`).
- At minimum: renders without crash, key user interactions, accessibility check (jest-axe).
- Coverage target: 70%+ on feature slices.
