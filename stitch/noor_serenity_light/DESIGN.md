# Design System Specification: Editorial Serenity

## 1. Overview & Creative North Star: "The Luminous Sanctuary"
This design system rejects the "boxed-in" nature of traditional digital interfaces in favor of a sprawling, high-end editorial experience. Our Creative North Star is **The Luminous Sanctuary**. We aim to recreate the feeling of sunlight filtering through a courtyard—airy, expansive, and deeply intentional.

To move beyond "standard" UI, we utilize **Intentional Asymmetry**. Do not feel obligated to center every element. Use generous, uneven white space (e.g., a `display-lg` headline offset to the left with body text tucked into a narrower column on the right) to create a sense of bespoke craftsmanship. We lean heavily into overlapping elements where typography breaks the bounds of image containers, suggesting depth and a non-rigid, fluid spirit.

---

## 2. Color & Tonal Architecture
The palette is rooted in an "Illuminated Neutral" philosophy. We use light not just as a background, but as a material.

### Primary Palette
*   **Primary (`#0d631b`)**: Used for high-impact brand moments and active states.
*   **Primary Container (`#2e7d32`)**: Our signature Soft Emerald. Use this for large, serene hero sections.
*   **Secondary (`#735c00`) & Secondary Fixed (`#ffe088`)**: Our Warm Gold. These are used sparingly to "light" the interface—think of them as metallic accents in a physical space.

### The "No-Line" Rule
Standard 1px borders are strictly prohibited for sectioning. Definition must be achieved through:
1.  **Background Shifts**: Transitioning from `surface` (`#f9f9f9`) to `surface-container-low` (`#f3f3f3`).
2.  **Signature Textures**: Use the `primary` to `primary-container` gradient for primary CTAs to give them a "soul" rather than a flat, plastic feel.
3.  **Geometric Micro-Patterns**: Use a subtle, SVG-based geometric Islamic pattern at 3% opacity on `surface-container-lowest` backgrounds to provide a tactile, premium paper quality.

### Glass & Gradient Rule
Floating elements (modals, navigation bars) should utilize **Glassmorphism**. Apply `surface-container-lowest` with an 80% opacity and a `backdrop-blur` of 20px. This ensures the vibrant emeralds and golds bleed through the edges, softening the UI.

---

## 3. Typography: The Editorial Voice
We pair the historical weight of Noto Serif with the modern clarity of Plus Jakarta Sans (our interpreted "clean" sans-serif).

*   **Display (Lg/Md/Sm) - Noto Serif**: Use for storytelling. These should be set with tighter letter-spacing (-0.02em) to feel like a high-end magazine header.
*   **Headline (Lg/Md/Sm) - Noto Serif**: Use for section titles. Pair these with a `secondary` (Gold) accent line or dot to anchor the eye.
*   **Title & Body - Plus Jakarta Sans**: These provide the functional "breath." Body text should never be pure black; use `on-surface-variant` (`#40493d`) to maintain a soft, serene contrast.
*   **The Hierarchy Rule**: Always jump at least two "steps" in size when placing a Headline next to Body text. This high-contrast scale is what separates "App UI" from "Premium Experience."

---

## 4. Elevation & Depth
We eschew traditional shadows in favor of **Tonal Layering**.

*   **The Layering Principle**: Treat the interface as stacked sheets of fine vellum. 
    *   Base: `surface`
    *   Content Area: `surface-container-low`
    *   Interactive Card: `surface-container-lowest` (this creates a "lift" through brightness rather than darkness).
*   **Ambient Shadows**: When a shadow is required for a floating CTA, use a 12% opacity tint of the `primary` color (`#0d631b`) with a 40px blur and 10px Y-offset. This creates an "Emerald Glow" rather than a grey smudge.
*   **The Ghost Border**: If a boundary is required for accessibility in forms, use `outline-variant` (`#bfcaba`) at **15% opacity**. It should be felt, not seen.

---

## 5. Components & Primitives

### Buttons
*   **Primary**: Full rounded (`9999px`). Background: `primary` to `primary-container` vertical gradient. Text: `on-primary`.
*   **Secondary**: `outline-variant` ghost border (20% opacity) with `primary` text.
*   **Interaction**: On hover, the button should scale 1.02x and the "Emerald Glow" shadow should intensify.

### Cards & Lists
*   **The "No-Divider" Rule**: Forbid horizontal lines. Use `spacing-8` (2.75rem) to separate list items, or use alternating `surface-container` background shifts.
*   **Roundedness**: All cards must use `rounded-xl` (3rem) or `rounded-full` (9999px) for smaller chips. This reinforces the "Serenity" aspect—no sharp edges.

### Inputs
*   **Style**: Minimalist. Only a bottom-border using the "Ghost Border" rule. On focus, the border transitions to a `secondary` (Gold) gradient.
*   **Helper Text**: Always use `label-sm` in `tertiary` (`#6b4f45`) to provide a warm, human tone.

### Signature Component: The "Peace-Progress" Bar
*   A custom progress indicator for spiritual or task-based tracking. Use a `surface-container-highest` track and a `secondary` (Gold) fill that glows slightly.

---

## 6. Do's and Don'ts

### Do:
*   **Use Whitespace as a Feature**: Give your headlines 2x more space than you think they need.
*   **Layer Patterns**: Place geometric patterns only on the lowest z-index layer to avoid clashing with text.
*   **Nesting**: Place `surface-container-lowest` cards inside `surface-container-low` sections to create soft depth.

### Don't:
*   **Don't use pure black (#000)**: It breaks the serenity. Use `on-surface` (`#1a1c1c`) for text.
*   **Don't use 1px solid dividers**: They create visual noise and "trap" the content.
*   **Don't use sharp corners**: Even `rounded-sm` (0.5rem) is too sharp for this system. Stick to `DEFAULT` (1rem) and above.
*   **Don't crowd the edges**: Keep a minimum "Safe Zone" of `spacing-6` (2rem) from the screen edge for all content.