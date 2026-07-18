Create one horizontal animation strip for Codex pet `gyeom`, state `waiting`.

Use the attached canonical base for identity. Use the attached layout guide only for slot count, spacing, centering, and padding; do not draw the guide.

Output exactly 6 full-body frames in one left-to-right row on flat pure user-selected #FF00FF. Treat the row as 6 invisible equal-width slots: one centered complete pose per slot, evenly spaced, with no overlap, clipping, empty slots, labels, or borders.

Identity: same pet in every frame: Sole identity source: warm clay/3D-toy young Korean man; thick black center-parted wavy hair, brown eyes, gentle expression; same slim youthful body in every frame. Strict outfit lock: light-gray heather raglan torso panel with black collar, shoulders, and sleeves; dark indigo-black straight cuffed denim jeans with subtle copper seams; charcoal black canvas low-top sneakers with off-white toe caps and white laces. Never use alternate pants, colors, garment designs, shoes, head sizes, limb lengths, or body proportions. Hard geometry lock for every generated strip: exactly the required number of complete, isolated whole-body poses in a single horizontal row; each pose has generous chroma-only space on both sides and never touches or overlaps a neighboring pose; all foreground stays inside the outer canvas with at least 24px source padding; every pose uses the same apparent 150px body height and the same baseline. For crouching, jumping, failure, and running, change articulation or vertical position only, never enlarge the head, torso, limbs, or shoes. Flat #FF00FF background only; no shadows, detached fragments, effects, text, scenery, or color fringe.. Preserve silhouette, face, proportions, markings, palette, material, style, and props.
Style: Pet-safe sprite: compact full-body mascot, readable in a 192x208 cell, clear silhouette, simple face, stable palette/materials, and crisp edges for chroma-key extraction. Style `clay`: Handmade clay or polymer-clay mascot with rounded sculpted forms, soft material texture, simple features, and clean readable edges. User style notes: Rigid identity and geometry lock. Keep the full body approximately the same height as the reference in every frame. Draw poses smaller with wide gaps rather than filling slots. Reject overlapping or clipped pose groups..
Animation continuity: keep apparent pet scale and baseline stable within the row unless the state itself intentionally changes vertical position, such as `jumping`. Move the pose within the slot instead of redrawing the pet larger or smaller frame to frame.

State action: Needs-input loop: expectant asking pose for approval, help, or user input.

State requirements:
- Show that Codex needs approval, help, or user input through an expectant asking pose.
- Keep the motion patient and readable, without turning it into ordinary idle or review.

Clean extraction: crisp opaque edges, safe padding, no scenery, text, guide marks, checkerboard, shadows, glows, motion blur, speed lines, dust, detached effects, stray pixels, or chroma-key colors inside the pet.
