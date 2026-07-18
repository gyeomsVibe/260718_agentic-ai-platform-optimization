# Gyeom Codex Pet — lossless handoff checkpoint

Checkpoint time: 2026-07-16 04:30 KST<br>
Status: **v2 direction expansion active; standard motion-delta gate passed**

## 1. Resume objective

Continue building and installing the custom Codex pet derived from 윤겸스's seven canonical clay-avatar references. The standard 9-state rows passed the motion-delta gate; continue the v2 16-direction look system and install only after final validation.

## 2. Authoritative run

- Run directory: `C:\tmp\gyeom-character-pet-20260715-master`
- Skill: `C:\Users\Kimyoongyeom\.codex\skills\hatch-pet\SKILL.md`
- Explicit mode: `MIA모드 발동` / `plan-review-execute`
- Final pet package is **not installed yet**.

## 3. Canonical character sources

Use only these seven character images and their master composite:

- `E:\사진\(내사진) 프로필_파일\# Make My Avatar\01_main_profile (0).png`
- `E:\사진\(내사진) 프로필_파일\# Make My Avatar\02_playful_v (0).png`
- `E:\사진\(내사진) 프로필_파일\# Make My Avatar\03_calm_hand_cheek (0).png`
- `E:\사진\(내사진) 프로필_파일\# Make My Avatar\04_thoughtful (0).png`
- `E:\사진\(내사진) 프로필_파일\# Make My Avatar\05_idea_finger (0).png`
- `E:\사진\(내사진) 프로필_파일\# Make My Avatar\06_cheerful_thumbsup (0).png`
- `E:\사진\(내사진) 프로필_파일\# Make My Avatar\07_cozy_coffee (0).png`
- `E:\사진\(내사진) 프로필_파일\# Make My Avatar\00-1_합본 마스터 이미지.png`

The file below is **method-only**. Do not copy or infer the depicted person's face, hair, clothes, or identity. Use only the abstract front/back/left/right/top turnaround concept:

- `E:\사진\(내사진) 프로필_파일\# Make My Avatar\00_5컷 턴어라운드 시트.png`

Identity constraints:

- Thick black wavy hair, brown eyes, warm clay/toy face, polished clay texture.
- One two-tone long-sleeve top: black sleeves/shoulders/neck surround plus one continuous light-gray front torso panel.
- No zipper, hoodie, jacket, outerwear, or layered shirt.
- No source-scene props or detached effects: question mark, bulb, heart, coffee cup, plants, text, scenery, glow, or shadow.

## 4. Verified completed work

- Canonical base generated and copied to `decoded\base.png` and `references\canonical-base.png`.
- All standard jobs are marked complete and passed the motion-delta gate: `base`, `idle`, `running-right`, `running-left`, `waving`, `jumping`, `failed`, `waiting`, `running`, and `review`.
- The five corrected strips remain in `decoded`; superseded versions remain under `decoded\archive`.
- The two problematic directional rows were re-extracted with component-based extraction.
- `frames\running-right\00.png` through `07.png` match the verified experiment set byte-for-byte.
- `frames\running-left\00.png` through `07.png` match the verified experiment set byte-for-byte.
- Previous stable-slot directional frames are preserved at:
  - `frames\archive\running-right-stable-v1`
  - `frames\archive\running-left-stable-v1`
- `frames\frames-manifest.json` records `components` for both directional rows.
- Structural inspection of each experiment returned `ok: true`, with no errors or warnings.

## 5. Important state distinction

The directional **frame folders are current**, but the files below are stale intermediate outputs created before the component-frame merge and must be rebuilt before visual acceptance:

- `final\spritesheet.png`
- `final\spritesheet.webp`
- `qa\contact-sheet.png`
- `qa\previews\*.gif`
- `qa\review.json`

Do not treat the existing atlas/contact sheet as evidence for the merged directional frames.

## 6. Last command and stop reason

The requested pause occurred while starting the standard rebuild. The command failed before atlas composition at the first Python inspection step:

```text
ModuleNotFoundError: No module named 'PIL'
```

No new atlas was composed by that failed command. This is an environment/runtime selection issue, not an image or frame failure.

## 7. Exact safe resume point

1. Re-read this checkpoint and the complete `hatch-pet` skill.
2. Load the bundled workspace dependencies and select a Python runtime that includes Pillow (`PIL`). Do not install a package unless the user separately approves installation at that time.
3. Re-run, in this order:
   - `inspect_frames.py` for all frames with `--require-components --allow-stable-slots`
   - `compose_atlas.py`
   - `make_contact_sheet.py`
   - `render_animation_previews.py`
4. Give the rebuilt contact sheet and GIFs to a lightweight visual-QA worker. Confirm no foot/arm clipping, detached fragments, scale popping, baseline jumps, identity drift, or wrong run direction.
5. If standard QA passes, write `qa\look-mechanics.md` for the Gyeom character and continue with `look-cardinals`, `look-row-9`, and `look-row-10` according to the v2 skill contract.
6. Run deterministic v2 assembly, chroma despill exactly once, atlas validation, labeled direction QA, three blind direction reviews, continuity review, and final visual QA.
7. Only after all gates pass, install under `C:\Users\Kimyoongyeom\.codex\pets\<pet-id>` with `spriteVersionNumber: 2`.

## 8. Current quality status and pending work

- `qa/motion-delta-gate.json` confirms meaningful adjacent-frame differences for every standard row (24%–55% changed pixels). Standard rows have a motion pass.
- `look-cardinals` has been generated and extracted successfully after this checkpoint; `qa/cardinal-anchors.json` reports four cleanly extracted anchors. It is not yet a final direction pass.
- Optimize remaining work by generating only the two required 8-cell v2 direction rows and performing final atlas assembly once.
- The full evidence and optimized execution design are recorded in `MIA_GYEOM_PET_OPTIMIZATION_DECISION_2026-07-16.md`.

## 9. Pending job states

- `look-cardinals`: pending
- `look-row-9`: pending
- `look-row-10`: pending

The four cardinal anchors were generated and extracted after the original pause. No 8-cell v2 direction row has started.

## 10. Integrity fingerprints

Use SHA-256 to detect accidental changes before resuming:

| File | SHA-256 |
|---|---|
| `pet_request.json` | `3D8F73A1CAF0ADCE6921B165CB3B444E2268455B5085BBD2348B2B06DF892BC7` |
| `imagegen-jobs.json` | `C22C0B891E042926C931D0133CF5DD8F1EAABD9E02B4D1F59AF787B524B1E820` |
| `frames\frames-manifest.json` | `BA8090CE71F31F2107BD7B688AABF3EAF584D44A22A352856B55769CB3E1E637` |
| stale `qa\review.json` | `4A151ED0348918E9D2888D263BDCC795219E0E32D13E869F6B9EDFA32E4C50CD` |
| stale `final\spritesheet.webp` | `EE7B61D473873AD707D5FA019A21D2658B4E7B197E10E069CC8607E6BB24913C` |
| stale `qa\contact-sheet.png` | `598C7F91397588712A7627EC0C39E94697CD8B9A55E89AE0FD03C1293C895C72` |

The stale-file hashes are recorded only to identify the pre-merge outputs; they are expected to change after the proper rebuild.

## 11. Safety boundary

- Do not delete generated sources, archives, prompts, or QA evidence until the final v2 package is validated and installed.
- Do not overwrite the seven canonical references.
- Do not install, publish, commit, push, or modify global rules as part of resume unless the user explicitly expands the scope.
- On the next user message, continue only if the user explicitly asks to resume.

## 12. Current v2 candidate checkpoint

- All 13 generation jobs are complete. The final v2 candidate is `C:\tmp\gyeom-character-pet-20260715-master\final\spritesheet-v2-despilled.png` (and matching WebP).
- `qa\v2-atlas-validation-despilled.json` passed: 8 columns, 11 rows, v2, RGBA, no transparency or chroma errors.
- `qa\direction-continuity-current.json` passed with review-required continuity warnings, notably at the `337.5 -> 000` wrap.
- A blind direction review sheet and hidden key were prepared. No independent blind reviewers were available in this session, so the package has not been installed.
- `imagegen-jobs.pre-v2-look-complete.json` is the pre-completion manifest backup. No source image or archive was deleted.

## 13. Final installation update (2026-07-16)

- The final installation candidate is `C:\tmp\gyeom-character-pet-20260715-master\final\spritesheet-v2-bgfixed.webp`.
- An independent visual review found opaque magenta backgrounds in standard rows `0, 3-8`. A separate, non-destructive candidate removed only those background pixels; the original `spritesheet-v2-despilled.*` files remain preserved.
- `qa\v2-atlas-validation-bgfixed.json` and `qa\installed-package-validation.json` both pass: RGBA, `1536x2288`, 8x11 grid, `spriteVersionNumber: 2`, and no transparent-RGB residue.
- Three isolated blind direction reviews were combined. `qa\direction-blind-validation.json` passes; all cardinal pairs pass. Intermediate diagonal uncertainty is documented as accepted minor review evidence in `qa\blind-review-resolution.json` and `qa\direction-semantics.json` contains all 16 explicit semantic verdicts with no failures.
- A fresh post-fix visual QA review passes. `qa\look-continuity.json` records that remaining continuity metrics are reviewed warnings only, with no visible reversal, snap, identity break, or background issue.
- The package is installed at `C:\Users\Kimyoongyeom\.codex\pets\gyeom\` with `pet.json` and `spritesheet.webp`. The packaged WebP SHA-256 is `BDE8608B3B805369F2DCB4E5FBCD996DFCCA1A090F941B21CE231E7143FD60AE`.
- Resume point: the build itself is complete. Only a user-facing Codex pet picker refresh/reload and optional subjective visual selection remain; do not regenerate rows unless the user identifies a specific visual defect.
