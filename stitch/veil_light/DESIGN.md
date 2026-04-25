---
name: Veil Light
colors:
  surface: '#fbf9f0'
  surface-dim: '#dcdad2'
  surface-bright: '#fbf9f0'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f4eb'
  surface-container: '#f0eee5'
  surface-container-high: '#eae8df'
  surface-container-highest: '#e4e3da'
  on-surface: '#1b1c17'
  on-surface-variant: '#3e4946'
  inverse-surface: '#30312b'
  inverse-on-surface: '#f3f1e8'
  outline: '#6e7976'
  outline-variant: '#bec9c5'
  surface-tint: '#046b5e'
  primary: '#004f45'
  on-primary: '#ffffff'
  primary-container: '#00695c'
  on-primary-container: '#94e5d5'
  inverse-primary: '#84d5c5'
  secondary: '#775a19'
  on-secondary: '#ffffff'
  secondary-container: '#fed488'
  on-secondary-container: '#785a1a'
  tertiary: '#464644'
  on-tertiary: '#ffffff'
  tertiary-container: '#5e5d5b'
  on-tertiary-container: '#d9d6d3'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#a0f2e1'
  primary-fixed-dim: '#84d5c5'
  on-primary-fixed: '#00201b'
  on-primary-fixed-variant: '#005046'
  secondary-fixed: '#ffdea5'
  secondary-fixed-dim: '#e9c176'
  on-secondary-fixed: '#261900'
  on-secondary-fixed-variant: '#5d4201'
  tertiary-fixed: '#e5e2df'
  tertiary-fixed-dim: '#c8c6c3'
  on-tertiary-fixed: '#1c1c1a'
  on-tertiary-fixed-variant: '#474745'
  background: '#fbf9f0'
  on-background: '#1b1c17'
  surface-variant: '#e4e3da'
typography:
  headline-lg:
    fontFamily: Noto Serif
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Noto Serif
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Noto Serif
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Noto Serif
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Noto Serif
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Noto Serif
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Noto Serif
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.08em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 8px
  container-padding: 24px
  gutter: 16px
  stack-sm: 4px
  stack-md: 12px
  stack-lg: 32px
---

## Brand & Style

The design system is centered on the concept of "spiritual translucence." It evokes the sensation of morning sunlight filtering through a sheer linen veil—bright, ethereal, and calming. The brand personality is one of quiet reverence and sophisticated clarity, aimed at users seeking a peaceful, distraction-free environment for their daily spiritual practices.

The visual style leans heavily into **Minimalism** with a focus on high-quality typography and intentional whitespace. It avoids heavy shadows or aggressive gradients, instead using subtle shifts in warm neutrals to define structure. The result is an interface that feels lightweight yet authoritative, balancing modern digital utility with a timeless, literary aesthetic.

## Colors

The color palette of this design system is anchored by a warm, off-white foundation that reduces eye strain compared to pure white. The primary **Teal (#00695C)** provides a deep, grounding contrast, used for core actions and primary brand moments. The **Gold (#C5A059)** serves as a sophisticated accent, reserved for highlights, active states, and ornamentation.

A series of warm, light greys are used to create "tonal depth" without introducing harsh lines. These greys should always lean toward a yellow/red hue rather than blue to maintain the "sunlight" warmth. High contrast is maintained for all text elements to ensure maximum readability against the airy background.

## Typography

This design system exclusively utilizes **Noto Serif** to achieve a classic, sophisticated feel. The typography is treated with an editorial mindset, utilizing generous line heights to enhance the "airy" quality of the layout. 

Headlines are set with a slight negative letter spacing to create a compact, premium appearance, while labels and small captions use increased letter spacing and uppercase styling to ensure clarity and a sense of "order." The serif forms provide a literary rhythm that aids in long-form reading, essential for spiritual texts or contemplative content.

## Layout & Spacing

The layout philosophy follows a **fixed-grid** approach for mobile and a structured fluid model for larger displays. This design system prioritizes "breathability," utilizing wide margins and significant vertical stacking distances to separate different functional blocks.

A 12-column grid is used for tablet and desktop, while mobile views rely on a standard 4-column structure with 24px side margins. Elements should never feel crowded; when in doubt, increase the `stack-lg` spacing to provide the "airy" feel required by the brand.

## Elevation & Depth

This design system avoids heavy shadows, instead using **tonal layers** and **low-contrast outlines**. Depth is communicated through the subtle contrast between the background (#FDFCFB) and the surface (#FFFFFF). 

For interactive elements like cards or modals, a very soft, diffused ambient shadow is used—sampled from the primary teal but with extremely low opacity (approx. 4-6%). This creates a "lifted" effect that mimics a physical paper layer resting on a light-filled surface. Ghost borders (1px solid lines using a light warm grey) are preferred over shadows for defining input fields and container boundaries.

## Shapes

The shape language of this design system is **Soft**. It utilizes a 0.25rem (4px) base corner radius, which provides a hint of approachability while maintaining the formal, structured look of the serif typography. 

Larger containers like cards use `rounded-lg` (8px), while smaller elements like tags or selection indicators use the base `rounded` (4px). This restrained use of rounding ensures the interface feels timeless and professional rather than overly playful.

## Components

### Buttons
Primary buttons use the Teal fill with white Noto Serif text. Secondary buttons use the Gold accent as an outline or as text-only with high letter spacing. Buttons should have a height of 48px to feel substantial and accessible.

### Cards & Lists
Cards are defined by the #FFFFFF surface color against the #FDFCFB background. They feature a 1px border in a soft warm grey rather than a shadow. List items include generous vertical padding (16px+) to maintain the airy aesthetic.

### Inputs
Text fields use a minimal "underline" style or a very light, ghost-bordered box. The label should always persist in a smaller, high-tracking Serif font to maintain a "classic document" look.

### Prayer-Specific Components
- **Time Indicators:** Use the Gold accent to highlight the "Current Prayer" with a subtle glow or a soft tonal background shift.
- **Qibla Compass:** A minimalist, thin-stroke vector design using Teal and Gold, avoiding heavy metallic textures in favor of clean lines.
- **Progress Indicators:** Thin, elegant lines rather than chunky bars, utilizing the primary teal to show completion.