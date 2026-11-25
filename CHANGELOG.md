# Update history

Record noteworthy changes to Mod Master XT here as they are made.
This history starts on 2026-11-13; it is not a complete record of older releases.

## Maintaining this file

- Update this file with every substantive code, behavior, or documentation change.
- Add dated entries under **Unreleased**, newest first, using `YYYY-MM-DD`.
- Group entries under **Added**, **Changed**, **Fixed**, **Removed**, or
  **Documentation**, omitting empty groups.
- Describe the user-visible result and any remaining limitations. Do not claim
  compilation, playback testing, or release availability unless verified.
- When releasing, move the relevant entries into a version heading with its
  release date and leave an **Unreleased** section for subsequent work.
- Preserve previous entries; correct inaccurate entries explicitly rather than
  silently rewriting history.

## Unreleased

### 2026-11-13

#### Fixed

- S3M loader: initialize the complete 32-channel effect-memory tables, rather
  than only the first 16 channels.
- S3M loader: handle null pattern offsets as empty 64-row patterns.
- S3M loader: validate the header signature, order-list size, offset-table
  bounds, packed-pattern bounds, and truncated events.
- S3M loader: reset channel-count detection for each module and limit the
  order-list end-marker search to the declared number of orders.
- S3M loader: prevent instrument numbers above the supported maximum from
  indexing the sample-use table.
- XM loader: convert key-off notes consistently in packed and unpacked pattern
  events.
- XM loader: validate the XM signature, version, header sizes, pattern and
  instrument data, sample headers, and file bounds before reading.
- XM loader: reject unsupported 256-row patterns rather than silently
  truncating them.

#### Added

- S3M loader: translation of the X panning effect to the existing internal
  panning command. Surround (`XA4`) remains unsupported.
- This ongoing update history, with maintenance and release-entry conventions.

#### Documentation

- Listed currently unsupported S3M effects: M, N, P, W, Y, Z, and tempo-slide
  T commands below hexadecimal `20`.
- Documented remaining XM limitations, including unsupported effects,
  incomplete volume-envelope handling, unsupported panning envelopes and
  linear-frequency mode, and pattern-count/row limits.

#### Validation

- S3M and XM changes passed whitespace checks. Compilation and playback have
  not been verified; no Pascal compiler was available on PATH during the
  checks.
