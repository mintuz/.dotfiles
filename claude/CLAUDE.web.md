# Web Development Guidelines for Claude

> **About this file:** Lean version optimized for context efficiency. Core principles here; detailed patterns loaded on-demand via skills.
>
> **Architecture:**
> - **CLAUDE.web.md** (this file): Web-specific core philosophy + quick reference (~150 lines, always loaded)
> - **Skills**: Detailed patterns loaded on-demand (react, frontend-testing, react-testing, tdd, css, refactoring, web-design)

## Always Load The Expectations Skill

- Skill: "core:expectations"
- Action: Load this skill every session before making changes.

## Core Philosophy

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

For detailed CSS patterns and architecture, load the `web:css` skill.

## Development Workflow

**Core principle**: RED-GREEN-REFACTOR in small, known-good increments.

**TDD Cycle:**
1. **RED**: Write failing test for desired behavior (start with simplest case)
2. **GREEN**: Write minimum code to make test pass (nothing more)
3. **REFACTOR**: Assess if refactoring adds value → commit working code FIRST → refactor → commit separately

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
