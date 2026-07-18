# Gyeom Pet — execution architecture correction

## Verified diagnosis

The standard animation rows are not static repeats. A dedicated `motion-delta-gate` compared adjacent RGBA frames and found meaningful change in every row: adjacent-pixel change ratios range from 24% to 55%. The earlier inference from equal non-transparent pixel counts and bounding boxes was incorrect; those summary values describe silhouette stability, not frame identity.

## Actual bottlenecks

1. The run used many small status checks and file actions across a protected work location. A measured document update took 0.9 seconds of work but about 147 seconds of execution-channel startup and approval overhead.
2. The pipeline did not expose a quantitative motion-delta result early, making status interpretation slower and less reliable.
3. Reopening the full reference set for incremental decisions created unnecessary context and image-processing work after the identity contract was already fixed.

## Optimized execution flow

1. Freeze the seven canonical sources, master composite, and identity contract.
2. Run `motion-delta-gate` once after standard frame extraction. It has passed for all nine standard rows.
3. Batch deterministic file work and validation together to reduce execution-channel round trips.
4. Continue only the three remaining v2 look assets in dependency order: cardinals, row 9, then row 10.
5. Compose and preview only once after both v2 rows pass. Do not rebuild final atlases after every intermediate action.

## Completion definitions

- **Structural pass:** extraction, dimensions, and alpha bounds are valid.
- **Motion pass:** adjacent frames visibly and measurably differ as intended.
- **Direction pass:** labeled 16 directions turn the head and body correctly.
- **Release pass:** structural, motion, direction, continuity, and final visual checks all pass.

Current status: standard rows have structural and motion passes; four cardinal anchors have an extraction pass. The two 8-cell v2 direction rows, final direction QA, and installation remain.