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
- **HATEOAS**: backend responses include a `links` field. Never hardcode API paths in components — resolve URLs from `links[rel]` via a `getLinkHref()` helper in `src/api/`.
- **Problem Details (RFC 7807)**: errors arrive as `application/problem+json`. Wrap `fetch` in a typed `apiFetch()` that throws an `ApiError(problem)` on non-OK responses. Display `problem.detail` to the user via React Query `onError`.
- Validate all API responses with a Zod schema before use.

## Error Boundaries

- Every route-level component **MUST** be wrapped in an `ErrorBoundary`.
- Map `ApiError.problem.status` → 401 redirect, 403 forbidden page, 404 not-found page, 5xx generic error.
- Wrap individual widgets for isolated failure (don't let one widget crash the whole page).

## Optimistic updates

- Use React Query `useMutation` with `onMutate` (cache snapshot), `onError` (rollback), `onSettled` (re-validate) for all mutations that change visible state.
- Never leave the UI in an inconsistent state — always provide `onError` rollback.

## Form validation

- Use **react-hook-form** + **Zod** for all forms; never build custom validation logic.
- Zod schemas live in `src/schemas/` and are shared with API response validation.
- Disable the submit button while `isSubmitting`. Associate errors with `role="alert"`.

## Code splitting, Suspense & loading states

### General loading rule
- Every waiting state > 200 ms **must** be materialised without layout shift (CLS = 0).
- Loading hierarchy: **skeleton → progress bar → spinner**. Never a full-screen spinner on a page with known structure.

### Lazy components
- Load routes, charts, modals, editors via `React.lazy()` + `<Suspense fallback={<SkeletonComponent />}>` — never use a spinner as `fallback`.
- Lazy boundary = critical bundle split. Apply at route level minimum.

### Skeletons
- Use `<Skeleton />` from shadcn/ui shaped like the actual content (match width/height).
- Centralise skeletons per entity (e.g. `components/skeletons/UserCardSkeleton.tsx`).
- Add `aria-busy="true"` on the container while loading. Respect `prefers-reduced-motion` (no animation when set).
- Show skeleton on `isPending` — **never hide existing content** during a background refetch (`isFetching`).

### Progress bar
- Use a **determinate** progress bar (`<Progress value={n} />`) whenever a real percentage exists (upload, export, batch job).
- Use a top-of-page indeterminate loader for route transitions only.

### Images
- Every image **must** have `loading="lazy" decoding="async"` plus explicit `width` + `height` (or `aspect-ratio`) to prevent CLS.
- Use a LQIP/blur placeholder for images above the fold.
- Reserve `loading="eager"` only for the LCP image.

## Routing

- Use **TanStack Router** (`@tanstack/react-router`). No React Router.
- Configure anti-flash thresholds: `defaultPendingMs: 200`, `defaultPendingMinMs: 400`, `defaultPendingComponent: <RouteSpinner />`.
- Route definitions in a typed route tree (`src/routes/`); components loaded lazily with `React.lazy`.
- Guard protected routes with an `AuthGuard` loader or `beforeLoad` hook.

## i18n

- All user-facing strings **must** go through `react-i18next` (`useTranslation` hook).
- No hardcoded UI text in components. Translation keys in `src/i18n/locales/`.
- Supported locales from V1: `fr`, `en`.

## Styling

- Prefer Tailwind CSS utility classes.
- No inline `style` props except for dynamic computed values.
- Component-scoped CSS modules are acceptable for complex animations.

## Mobile / Responsive

- All React UIs must be **fully usable on mobile** (see base.md Mobile / Responsive rules).
- Use Tailwind responsive prefixes (`sm:`, `md:`, `lg:`) — never write separate media query blocks manually.
- Navigation: use a collapsible drawer (`Sheet` / `Drawer` component) or a bottom tab bar on mobile; never leave a full desktop sidebar visible on small screens.
- Typography: `text-sm` minimum on mobile; never use font sizes below 14px for body copy.
- Forms: inputs must be at least 44px tall on mobile; stack labels above inputs (not inline).
- Modals and panels should be full-screen (`inset-0`) on screens < 540px.
- Touch interactions: add `touch-action: manipulation` on all button/link elements to eliminate 300ms delay.
- **Playwright E2E tests must include at least one viewport test at 390×844** (iPhone 14 size) for each critical flow.

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
