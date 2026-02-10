---
name: accessibility-compliance
description: Ensure web applications meet WCAG 2.2 Level AA accessibility standards. Use when the user asks about accessibility, a11y compliance, screen readers, keyboard navigation, or ARIA attributes.
license: MIT
---

# Accessibility Compliance

## Goal

Ensure web UI meets **WCAG 2.2 Level AA** compliance using the POUR principles.

## The POUR Principles

- **Perceivable**: Users must differentiate content (color contrast, alt text).
- **Operable**: UI must be navigable (keyboard navigation, no focus traps).
- **Understandable**: Info and UI must be readable (form labels, error handling).
- **Robust**: Content must be interpreted by assistive tech (semantic HTML, ARIA).

## Workflow

### Step 1: Use Semantic HTML

Always use the correct element. Do not use `<div>` or `<span>` when a semantic element exists.

| Use This | Instead of This |
|----------|-----------------|
| `<button>` | `<div onClick=...>` |
| `<a href="...">` | `<span onClick=...>` |
| `<main>` | `<div id="main">` |
| `<nav>` | `<div class="nav">` |
| `<header>` / `<footer>` | `<div class="header">` |

```jsx
// ❌ Bad
<div className="button" onClick={submit}>Submit</div>

// ✅ Good
<button type="button" onClick={submit}>Submit</button>
```

### Step 2: Images and Media

- **Alt text**: MANDATORY for all `<img>` tags.
  - Decorative images: `alt=""`
  - Informative images: describe the content concisely.
- **Captions**: Provide captions or transcripts for all audio/video.

```html
<!-- ❌ Bad -->
<img src="chart.png" />

<!-- ✅ Good (informative) -->
<img src="chart.png" alt="Bar chart showing 20% growth in Q3" />

<!-- ✅ Good (decorative) -->
<img src="divider.png" alt="" />
```

### Step 3: Keyboard Navigation

- Interactive elements MUST be focusable via `Tab`.
- NEVER remove `outline` without a high-contrast alternative.
- Use logical DOM order. Avoid positive `tabindex` values.

### Step 4: Forms

- Every input MUST have a label.
- Connect label to input via `for`/`id` or nesting.
- Error messages must be text (not just color) and linked via `aria-describedby`.

```html
<!-- ❌ Bad -->
<input type="text" placeholder="Search" />

<!-- ✅ Good -->
<label for="search">Search</label>
<input id="search" type="text" />
```

### Step 5: Color Contrast

- **Text**: minimum **4.5:1** contrast ratio (3:1 for large text).
- **UI Components**: minimum **3:1** for borders.
- Don't rely on color alone to convey meaning.

### Step 6: ARIA (when needed)

**No ARIA is better than bad ARIA.** Use semantic HTML first.

- `role`: Only when no HTML element exists (e.g., `role="tablist"`).
- `aria-label`: Invisible label for screen readers.
- `aria-expanded`, `aria-hidden`, `aria-invalid`, `aria-pressed`: State attributes.

### Step 7: Audit

```bash
# Linting
npx eslint --plugin jsx-a11y .

# Automated audit
npx lighthouse --only-categories=accessibility <URL>
npx axe <URL>
```

## Checklist

- [ ] All images have `alt` attributes
- [ ] Forms have labels connected to inputs
- [ ] Keyboard navigation works (Tab/Enter/Space)
- [ ] Focus indicators are visible
- [ ] Color contrast passes WCAG AA (4.5:1 text, 3:1 UI)
- [ ] HTML is semantic (`<button>`, `<a>`, `<nav>`, etc.)
- [ ] No ARIA misuse (semantic HTML preferred)
- [ ] `eslint-plugin-jsx-a11y` or equivalent passes

## Constraints

- **NEVER** remove focus outlines without providing a visible alternative.
- **NEVER** use `<div>` or `<span>` for interactive elements.
- **ALWAYS** provide alt text for informative images.
- **ALWAYS** associate labels with form inputs.
