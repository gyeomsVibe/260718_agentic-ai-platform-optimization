# Gyeom look mechanics

## Identity lock

Keep the same warm clay face, thick black center-parted wavy hair, brown eyes, youthful slim proportions, light-gray raglan torso with black collar/shoulders/sleeves, dark indigo-black cuffed denim jeans with subtle copper stitching, and charcoal canvas shoes in every direction. Feet, lower-leg scale, torso width, and baseline remain anchored.

## Natural gaze motion

The eyes lead; the pupils, eyelids, and eyebrows change together within the existing brown eyes. The head and neck follow with a restrained turn or pitch, then the shoulders and upper torso follow by a smaller amount. The lower body and feet stay registered. Do not rotate, skew, or tilt the whole sprite. Do not alter facial proportions, garment construction, colors, cuffs, stitching, shoes, or hair mass.

## Cardinal families

- `000 up`: eyes lift, upper eyelids rise, chin and nose tip lift subtly; face remains readable from the front with a slight neck extension.
- `090 screen-right`: pupils, nose tip, head, and shoulders turn toward the viewer's right; more of the character's screen-left facial side is visible.
- `180 down`: eyes lower, upper eyelids narrow gently, chin and nose tip lower; the torso leans forward very slightly without covering the face.
- `270 screen-left`: pupils, nose tip, head, and shoulders turn toward the viewer's left; more of the character's screen-right facial side is visible.

## Continuity budget

Each 22.5-degree step advances eyes, head, neck, and shoulder follow-through by an even small amount. Keep the same lower-body anchor and scale. `337.5` must lead smoothly into `000`; `157.5` must lead smoothly into `180`. No extra props, shadows, text, glow, detached effects, color changes, or clothing substitutions.
