# Design System: The Divine Canvas

## 1. Overview & Creative North Star
**Creative North Star: "The Celestial Veil"**

This design system is not a utility; it is a digital sanctuary. We move beyond the "app as a tool" mindset to "app as an experience." The aesthetic is rooted in **The Celestial Veil**—a philosophy where information is revealed through layers of light, depth, and translucency. 

To achieve a "High-End Editorial" feel, we reject the rigid, boxy constraints of standard Material Design. We embrace **intentional asymmetry**, allowing Noto Serif headings to breathe with generous leading, and using **tonal depth** instead of structural lines. This system mimics the quiet atmosphere of a moonlit masjid: deep shadows, glowing accents, and the soft blur of frosted glass.

---

## 2. Colors & Surface Philosophy
The palette is anchored in a profound Deep Teal, illuminated by Secondary Gold accents that signify sacredness and time.

### The "No-Line" Rule
**Explicit Instruction:** Solid 1px borders are strictly prohibited for sectioning or containment. We define space through:
1.  **Background Shifts:** Transitioning from `surface` to `surface-container-low`.
2.  **Tonal Transitions:** Using the `surface-container` hierarchy to denote importance.
3.  **Proximity:** Utilizing the spacing scale to create mental groupings.

### Surface Hierarchy & Nesting
Treat the UI as physical layers of fine material.
*   **Base:** `surface` (#0d1514) – The infinite foundation.
*   **Sections:** `surface-container-low` (#151d1c) – Subtle grouping for secondary information.
*   **Interactive Cards:** `surface-container-high` (#232c2a) – Primary focus areas.
*   **Floating Elements:** `surface-container-highest` (#2e3635) – Critical navigation or modals.

### The "Glass & Gradient" Rule
To evoke a spiritual, premium feel, all floating overlays must utilize **Glassmorphism**.
*   **Token:** `surface-variant` at 40-60% opacity.
*   **Effect:** `backdrop-blur: 20px`.
*   **Soulful Gradients:** For primary CTAs (e.g., "Start Prayer"), use a linear gradient from `primary` (#94d3c1) to `primary-container` (#004d40) at a 135-degree angle. This adds "visual soul" that flat colors cannot replicate.

---

## 3. Typography
We pair the timeless authority of **Noto Serif** with the modern precision of **Manrope**.

| Level | Token | Font Family | Size | Character |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Noto Serif | 3.5rem | Editorial, poetic impact. |
| **Headline** | `headline-md` | Noto Serif | 1.75rem | Spiritual guidance/Section headers. |
| **Title** | `title-lg` | Manrope | 1.375rem | Bold, navigational clarity. |
| **Body** | `body-lg` | Manrope | 1rem | High-readability content. |
| **Label** | `label-md` | Manrope | 0.75rem | Technical data (Prayer times). |

**Editorial Note:** Use `headline-lg` with asymmetrical alignment (e.g., left-aligned with a large right margin) to create a premium magazine layout feel.

---

## 4. Elevation & Depth
We replace "drop shadows" with **Tonal Layering**.

*   **The Layering Principle:** To "lift" a prayer card, do not add a shadow. Place a `surface-container-high` element onto a `surface` background. The color shift provides a natural, sophisticated lift.
*   **Ambient Shadows:** If a floating modal requires a shadow, it must be tinted. Use 8% opacity of `on-surface` with a 40px blur. Never use pure black.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility (e.g., input fields), use `outline-variant` at 15% opacity. It should feel like a whisper of a line, not a boundary.

---

## 5. Components

### Buttons & CTAs
*   **Primary:** A gradient of `primary` to `primary-container`. `border-radius: DEFAULT (0.25rem)` for a sharp, architectural look.
*   **Secondary (Gold):** `on-secondary-container` text on a transparent background with a "Ghost Border" of `secondary`. Use for "Sunnah" or optional actions.

### Prayer Time Cards
*   **Styling:** No dividers. Use a `surface-container-low` background. 
*   **Active State:** Use a `primary` "glow" (a subtle 2px blurred outer stroke) to indicate the current prayer.
*   **Glassmorphism:** The "Next Prayer" countdown should be a floating glass card (`backdrop-blur`) over the main dashboard.

### Prayer Tracker (Chips)
*   **States:** Unselected chips are `surface-container-highest`. Selected chips transition to `secondary` (Gold) to signify completion and "reward."

### Input Fields
*   **Style:** Minimalist. No background fill. Only a bottom "Ghost Border" using `outline-variant`. Labels in `label-md` should sit 8px above the line.

### Religious Text (Quranic Verses)
*   **Component:** "The Verse Card."
*   **Styling:** `surface-container-highest` with `display-sm` (Noto Serif) text. Increased line-height (1.6) to allow the calligraphy-style typography to breathe.

---

## 6. Do's and Don'ts

### Do
*   **DO** use whitespace as a separator. If you feel the need for a line, add 16px of padding instead.
*   **DO** use the `secondary` (Gold) color sparingly. It is a "divine accent," used only for active prayer states or spiritual achievements.
*   **DO** ensure a contrast ratio of at least 7:1 for all `on-surface` text against `surface` backgrounds.

### Don't
*   **DON'T** use standard 1px solid borders. It breaks the "Celestial Veil" illusion.
*   **DON'T** use generic system icons. Use thin-stroke (1.5pt) custom icons that match the weight of the Manrope typeface.
*   **DON'T** use pure black (#000000). Always use the `surface` token (#0d1514) to maintain the deep teal "soul" of the dark theme.
*   **DON'T** crowd the layout. If the screen feels full, remove an element. Premium design is defined by what is left out.