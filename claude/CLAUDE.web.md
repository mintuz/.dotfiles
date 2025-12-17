# Web Development Guidelines for Claude

> **About this file:** Lean version optimized for context efficiency. Core principles here; detailed patterns loaded on-demand via skills.
>
> **Architecture:**
> - **CLAUDE.web.md** (this file): Web-specific core philosophy + quick reference (~150 lines, always loaded)
> - **Skills**: Detailed patterns loaded on-demand (react, frontend-testing, react-testing, tdd, css, refactoring, web-design)

## Core Philosophy

**TEST-DRIVEN DEVELOPMENT IS NON-NEGOTIABLE.** Every single line of production code must be written in response to a failing test. No exceptions.

Web development with React, TypeScript strict mode, behavior-driven testing, and feature-based architecture. All work should be done in small, incremental changes following the Red-Green-Refactor cycle.

## Quick Reference

**Key Principles:**

- Write tests first (TDD Red-Green-Refactor)
- Test behavior users see, not implementation
- Feature-based architecture with clear boundaries
- No `any` types or type assertions
- TypeScript strict mode always
- Avoid useEffect (most cases)
- Components have no margin (spacing controlled by parent)
- Commit before refactoring

**Preferred Tools:**

- **Language**: TypeScript (strict mode)
- **Framework**: React 18+
- **Testing**: Vitest + React Testing Library
- **Server State**: React Query
- **Styling**: Tailwind or CSS Modules
- **API Mocking**: MSW (Mock Service Worker)

## React Architecture

**Core principle**: Feature-based architecture with clear boundaries and colocation.

**Quick reference:**
- Features organized in `src/features/[feature]/{components,api,types,hooks}`
- Shared components in `src/components/`
- One feature cannot import from another feature
- Colocate related code (styles, tests, types with components)
- Composition over props drilling
- Avoid useEffect unless synchronizing with external systems

**Decision trees:**

Where should this component live?
```
Is it used by multiple features?
├── Yes → src/components/
└── No → src/features/[feature]/components/
```

What state solution should I use?
```
Is this data from an API?
├── Yes → React Query
└── No → Is it URL state (filters, pagination)?
    ├── Yes → React Router
    └── No → Is it needed globally?
        ├── Yes → Context/Zustand
        └── No → useState/useReducer
```

Do I need useEffect?
```
Why does this code need to run?
"Because the component was displayed"
├── Synchronizing with external system? → Yes: useEffect is appropriate
└── Otherwise → Probably don't need useEffect

"Because the user did something"
└── Put it in the event handler, not useEffect

"Because I need to compute a value"
└── Calculate during render (or useMemo if expensive)
```

For detailed React patterns and architecture, load the `web:react` skill.

## Testing Strategy

**Core principle**: Test behavior users see through the public API. Use DOM Testing Library with accessibility-first queries.

**Quick reference:**
- Write tests first (Red-Green-Refactor)
- Query priority: `getByRole` → `getByLabelText` → `getByText` → `getByTestId`
- Use `userEvent` with `setup()`, never `fireEvent`
- Use `findBy*` for async elements (loading, API responses)
- Use factory functions for test data (no `let`/`beforeEach`)
- Test through public API only (props → rendered DOM)
- No testing of component internals (state, methods)
- MSW for API mocking at network level

**React Testing Library patterns:**
- `render()` for components
- `renderHook()` for custom hooks
- `wrapper` option for context providers
- `screen` object for all queries (don't destructure from render)

For detailed testing patterns, load:
- `web:frontend-testing` - DOM Testing Library patterns
- `web:react-testing` - React-specific testing patterns
- `web:tdd` - TDD workflow and Red-Green-Refactor cycle

## CSS Architecture

**Core principle**: Single Responsibility with immutable utilities. Components have no margin.

**Quick reference:**
- Each class handles one concern only
- Components never have margin (spacing controlled by parent/utilities)
- Use `rem` for scalable sizing (font-size, spacing)
- Use `px` for fixed sizing (borders, shadows)
- No reactive `!important` (only proactive for utilities)
- No ID selectors for styling
- Longhand properties when only setting one value
- Accessibility first (semantic HTML before ARIA)

**Decision trees:**

Should I use px or rem?
```
Should this scale with user font preferences?
├── Yes → Use rem (font-size, vertical spacing, media queries)
└── No → Use px (borders, shadows, horizontal padding)
```

Should component have margin?
```
Is this a layout component (grid, stack, container)?
├── Yes → Margin/gap is appropriate
└── No → Move spacing to parent or use utility classes
```

For detailed CSS patterns and architecture, load the `web:css` skill.

## Development Workflow

**Core principle**: RED-GREEN-REFACTOR in small, known-good increments.

**TDD Cycle:**
1. **RED**: Write failing test for desired behavior (start with simplest case)
2. **GREEN**: Write minimum code to make test pass (nothing more)
3. **REFACTOR**: Assess if refactoring adds value → commit working code FIRST → refactor → commit separately

**Test factories pattern:**
```typescript
const getMockUser = (overrides?: Partial<User>): User => ({
  id: "user-1",
  name: "Test User",
  email: "test@example.com",
  ...overrides,
});

// Usage in tests
it("should display user name", () => {
  const user = getMockUser({ name: "John Doe" });
  render(<UserProfile user={user} />);
  expect(screen.getByText("John Doe")).toBeInTheDocument();
});
```

**Refactoring priorities:**
| Priority | Action | Examples |
|----------|--------|----------|
| Critical | Fix now | Mutations, knowledge duplication, >3 levels nesting |
| High | This session | Magic numbers, unclear names, >30 line functions |
| Nice | Later | Minor naming, single-use helpers |
| Skip | Don't change | Already clean code |

For detailed TDD workflow and refactoring methodology, load:
- `web:tdd` - TDD Red-Green-Refactor patterns
- `web:refactoring` - Refactoring assessment and priorities

## Design & Polish

**Core principle**: Visual hierarchy through weight, consistent spacing, accessibility first.

**Quick reference:**
- Add hierarchy with weight before color
- Use consistent spacing scale (4px or 8px base)
- Set max-width for readability (68-70ch for text, 1280px for pages)
- Define small text style scale and reuse it
- Ensure color contrast for accessibility
- Design all states (hover, active, focus, loading, error, success, disabled)
- Generous padding for clickable areas (12-16px vertical, 16-24px horizontal)
- Use spacing and alignment over visual clutter (borders, dividers)

For detailed design principles and component patterns, load the `web:web-design` skill.

## Summary

Web development requires feature-based architecture, behavior-driven testing, and thoughtful CSS architecture. Every change follows TDD (Red-Green-Refactor), tests verify user-visible behavior through accessible queries, and components are designed with clear boundaries and no margin. When in doubt, favor simplicity and user-centric testing over implementation details.
