---
trigger: glob
globs: ["*.html", "*.jsx", "*.tsx", "*.vue", "*.svelte", "*.php", "*.erb"]
---

# Accessibility (a11y) Best Practices

## 1. Web Content Accessibility Guidelines (WCAG 2.1)

Strive for **Level AA** compliance.

### The POLL Principles
- **Perceivable**: Users must differenciate content (Color contrast, Alt text).
- **Operable**: UI components must be navigable (Keyboard navigation, No focus traps).
- **Understandable**: Info and UI must be readable (Form labels, Error handling).
- **Robust**: Content must be interpreted by variety of agents (Semantic HTML, ARIA).

## 2. Semantic HTML

**Rule**: Always use the correct HTML element for the job. Do not use `<div>` or `<span>` when a semantic element exists.

| Use This | Instead of This | Why? |
|----------|-----------------|------|
| `<button>` | `<div onClick=...>` | Built-in keyboard accessibility and focus. |
| `<a href="...">` | `<span onClick=...>` | Built-in navigation and SEO. |
| `<main>` | `<div id="main">` | Landmark for screen readers to jump to content. |
| `<nav>` | `<div class="nav">` | Landmark for navigation. |
| `<header>` | `<div class="header">` | Contextual meaning. |
| `<footer>` | `<div class="footer">` | Contextual meaning. |

```jsx
// ❌ Bad
<div className="button" onClick={submit}>Submit</div>

// ✅ Good
<button type="button" onClick={submit}>Submit</button>
```

## 3. Images and Media

- **Alt Text**: MANDATORY for all `<img>` tags.
    - **Decorative images**: Use `alt=""`.
    - **Informative images**: Describe the content conciseley.
- **Captions**: Provide captions or transcripts for all audio/video.

```html
<!-- ❌ Bad -->
<img src="chart.png" />

<!-- ✅ Good (Informative) -->
<img src="chart.png" alt="Bar chart showing 20% growth in Q3" />

<!-- ✅ Good (Decorative) -->
<img src="divider.png" alt="" />
```

## 4. Keyboard Navigation

- **Focusable**: Interactive elements must be focusable via `Tab`.
- **Visible Focus**: Never remove outline (`outline: none`) without providing a high-contrast alternative.
- **Tab Order**: Use logical DOM order. Avoid positive `tabindex` values (e.g., `tabindex="1"`). Use `0` or `-1`.

## 5. Forms

- **Labels**: Every input MUST have a label.
- **Association**: Connect label to input via `for`/`id` or nesting.
- **Errors**: Error messages must be text (not just color) and linked to input via `aria-describedby`.

```html
<!-- ❌ Bad -->
<input type="text" placeholder="Search" />

<!-- ✅ Good (Explicit) -->
<label for="search">Search</label>
<input id="search" type="text" />

<!-- ✅ Good (Implicit) -->
<label>
  Search
  <input type="text" />
</label>

<!-- ✅ Good (Hidden label) -->
<label for="search" class="sr-only">Search</label>
<input id="search" type="text" />
```

## 6. Color Contrast

- **Text**: Minimum **4.5:1** contrast ratio for normal text. **3:1** for large text.
- **UI Components**: Minimum **3:1** for borders of inputs/buttons.
- **Color Independence**: Don't rely on color alone to convey meaning (e.g., error states should have text/icon).

## 7. ARIA (Accessible Rich Internet Applications)

**Rule**: No ARIA is better than bad ARIA. Use Semantic HTML first.

- **Role**: Use only when HTML element doesn't exist (e.g., `role="tablist"`).
- **Labels**: `aria-label` (invisible label) or `aria-labelledby` (references other element).
- **State**: `aria-expanded`, `aria-hidden`, `aria-invalid`, `aria-pressed`.

```jsx
// ✅ Correct use of ARIA for a toggle button
<button
  aria-pressed={isPressed}
  onClick={toggle}
>
  {isPressed ? 'Mute' : 'Unmute'}
</button>
```

## 8. Development Tools

- **Linting**: Use `eslint-plugin-jsx-a11y` or similar.
- **Browser**: Chrome/Firefox Accessibility Tree inspector.
- **Audit**: Lighthouse, axe DevTools.

## Checklist

- [ ] All images have `alt` attributes.
- [ ] Forms have labels.
- [ ] Keyboard navigation works (Tab/Enter/Space).
- [ ] Focus indicators are visible.
- [ ] Color contrast passes WCAG AA.
- [ ] HTML is semantic (`<button>`, `<a>`, `<nav>`, etc.).
