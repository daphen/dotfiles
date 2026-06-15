---
name: motion
description: Motion (formerly Framer Motion) React animation library - modern API patterns, correct imports, and best practices
---

# Motion for React

Motion is the animation library for React (previously called Framer Motion).

## Critical: Correct Import

```tsx
// CORRECT - Modern Motion
import { motion } from "motion/react"

// WRONG - Old Framer Motion (deprecated)
import { motion } from "framer-motion"  // DO NOT USE
```

## Basic Animation

```tsx
<motion.div animate={{ opacity: 1, x: 100 }} />
```

## Gesture Animations

```tsx
<motion.button
  whileHover={{ scale: 1.1 }}
  whileTap={{ scale: 0.95 }}
  whileFocus={{ outline: "2px solid blue" }}
/>
```

## Transitions

```tsx
// Duration-based
<motion.div
  animate={{ x: 100 }}
  transition={{ duration: 0.5, ease: "easeOut" }}
/>

// Spring physics (recommended for natural feel)
<motion.div
  animate={{ x: 100 }}
  transition={{ type: "spring", stiffness: 300, damping: 20 }}
/>

// Duration-based spring
<motion.div
  animate={{ x: 100 }}
  transition={{ type: "spring", duration: 0.8, bounce: 0.25 }}
/>
```

## Variants (for orchestrated animations)

```tsx
const variants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 }
}

<motion.div
  variants={variants}
  initial="hidden"
  animate="visible"
/>
```

## Staggered Children

```tsx
const container = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.1 }
  }
}

const item = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 }
}

<motion.ul variants={container} initial="hidden" animate="visible">
  {items.map(i => <motion.li key={i} variants={item} />)}
</motion.ul>
```

## Enter/Exit Animations (AnimatePresence)

```tsx
import { motion, AnimatePresence } from "motion/react"

<AnimatePresence>
  {isVisible && (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    />
  )}
</AnimatePresence>
```

## Layout Animations

```tsx
// Animate layout changes automatically
<motion.div layout />

// Shared layout animations
<motion.div layoutId="shared-element" />
```

## Scroll Animations

```tsx
import { motion, useScroll, useTransform } from "motion/react"

function Component() {
  const { scrollYProgress } = useScroll()
  const opacity = useTransform(scrollYProgress, [0, 1], [0, 1])

  return <motion.div style={{ opacity }} />
}
```

## whileInView (animate on scroll into view)

```tsx
<motion.div
  initial={{ opacity: 0, y: 50 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.5 }}
/>
```

## Drag

```tsx
<motion.div
  drag
  dragConstraints={{ left: 0, right: 300, top: 0, bottom: 300 }}
  dragElastic={0.2}
/>
```

## Common motion components

- `motion.div`, `motion.span`, `motion.p` - HTML elements
- `motion.button`, `motion.a`, `motion.input` - Interactive elements
- `motion.ul`, `motion.li` - Lists
- `motion.svg`, `motion.path`, `motion.circle` - SVG elements

## Animation Values

Motion can animate:
- Numbers: `x: 100`
- Strings with units: `x: "100px"`, `x: "50%"`, `x: "10vw"`
- Colors: `backgroundColor: "#ff0000"`, `color: "rgba(0,0,0,0.5)"`
- Complex values: `boxShadow: "0px 10px 20px rgba(0,0,0,0.2)"`

## Best Practices

1. Use `spring` transitions for interactive elements (hover, tap, drag)
2. Use `tween` with easing for scripted animations
3. Use `layout` prop for smooth size/position changes
4. Use `AnimatePresence` for exit animations
5. Use `whileInView` instead of scroll listeners for reveal animations
6. Keep animations subtle - 0.2-0.5s duration for micro-interactions
