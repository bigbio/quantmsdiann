# DIA-NN Enterprise 2.5.1 support

**Date:** 2026-06-03
**Status:** Design — approved, pending spec review

Add support for the **DIA-NN Enterprise** build (v2.5.1 preview), whose headline
feature is the **Knowledge Base** (`--kb`) option that boosts identifications
(mainly on human data). Enterprise also needs a **license key** at runtime.

Source: Enterprise package `DIA-NN-2.5.1-Enterprise-Linux.zip` (binary
`diann-linux`, a `Dockerfile`, and `models/base232.nnkb` — the bundled KB).
Guidance from Vadim Demichev (DIA-NN author).

## Scope

In scope:

1. A new **Enterprise version/profile/container** (separate from the academic image).
2. **`--diann_license`** runtime plumbing (param, with next-to-binary fallback).
3. **`--enable_kb`** flag, applied only to the **first-pass search**, gated to Enterprise.
4. Guards, docs, schema, CHANGELOG.

Out of scope:

- **`--auto-aff`** (CPU affinity, primarily Windows; this pipeline is Linux). Reachable via `--extra_args` if ever needed.
- **Extra QC metrics** (Empirical.Quality, peak-shape) — emitted automatically by the Enterprise report; no flag. We only confirm downstream parsing tolerates the extra columns.
- Building/publishing the container and committing the binary or license key — the binary is **not redistributable** and the license is a per-user secret. The container recipe lives in [`quantms-containers`](https://github.com/bigbio/quantms-containers); the repo only references the image tag.

## 1. Version / profile / container

The Enterprise image is a **separate repo** from the academic one (Vadim):
`ghcr.io/bigbio/diann-enterprise:2.5.1` (academic 2.5.1, if it ships, would be
`ghcr.io/bigbio/diann:2.5.1`).

- New `conf/diann_versions/v2_5_1_enterprise.config` + profile
  `diann_v2_5_1_enterprise` (registered in `nextflow.config` profiles), setting:
  ```groovy
  params.diann_version    = '2.5.1'
  params.diann_enterprise = true
  process {
      withLabel: diann { container = 'ghcr.io/bigbio/diann-enterprise:2.5.1' }
  }
  ```
- New default param `diann_enterprise = false` (in `nextflow.config` + schema).
  This boolean — not the version string — is the discriminator that unlocks
  Enterprise-only features, so `--kb` gating is correct even if an academic
  `2.5.1` profile is later added.
- The image bundles the binary + `models/base232.nnkb` (KB). It carries **no
  license key**.

## 2. License key (`--diann_license`)

DIA-NN reads the license either from a file next to the binary or via
`--license <path>` (both confirmed working). The key is a per-user secret and
must never be committed or baked into the shared image.

- New param `diann_license = null` (path).
- A value channel `ch_diann_license` is built once in `dia.nf`:
  `params.diann_license ? Channel.fromPath(params.diann_license, checkIfExists: true).first() : []`
  and passed as an **optional `path` input** to every DIA-NN process that runs
  the binary: `PRELIMINARY_ANALYSIS`, `INDIVIDUAL_ANALYSIS`,
  `ASSEMBLE_EMPIRICAL_LIBRARY`, `FINAL_QUANTIFICATION`,
  `INSILICO_LIBRARY_GENERATION`, `FINE_TUNE_MODELS` (and the `TUNE_*` aliases).
- In each module script: `def license_arg = license_file ? "--license ${license_file}" : ''`,
  interpolated into the `diann` command line.
- When `diann_license` is unset, `ch_diann_license = []` (empty), no `--license`
  is added, and DIA-NN falls back to a key next to the binary if present.

Staging into all DIA-NN processes (not just the `--kb` one) is intentional: the
Enterprise binary may validate the license at startup, and the extra QC metrics
require it regardless of `--kb`.

## 3. Knowledge base (`--enable_kb`)

- New param `enable_kb = false` (boolean).
- Applied as `--kb` **only in `PRELIMINARY_ANALYSIS`** — the first-pass search of
  runs against the large predicted library (and InfinDIA). Per Vadim it is
  ignored in the second pass, and it does not belong in library creation.
  Because `TUNE_PRELIMINARY_ANALYSIS` is the same module, fine-tuning's first-pass
  search picks it up too (consistent — also a predicted-library search).
- Module: `def kb = params.enable_kb ? '--kb' : ''` interpolated into the
  `PRELIMINARY_ANALYSIS` `diann` command.
- Not added to `INSILICO_LIBRARY_GENERATION`, `ASSEMBLE_EMPIRICAL_LIBRARY`,
  `INDIVIDUAL_ANALYSIS`, or `FINAL_QUANTIFICATION`.

## 4. Guards / validation (in `dia.nf`, mirroring existing version guards)

- `params.enable_kb && !params.diann_enterprise` →
  `error("--enable_kb requires the DIA-NN Enterprise build. Use -profile diann_v2_5_1_enterprise.")`
- If `params.enable_kb && !params.diann_license` → `log.warn` that a license is
  required for Enterprise/KB and, if none is provided, DIA-NN must find a key
  next to the binary or the run will fail. (Cannot detect a baked-in key from
  Nextflow, so warn rather than error.)

## Data flow

1. User runs `-profile diann_v2_5_1_enterprise,docker --diann_license key.txt --enable_kb`.
2. Guards pass (`diann_enterprise == true`).
3. `ch_diann_license` carries `key.txt`; every DIA-NN process stages it and adds `--license key.txt`.
4. `PRELIMINARY_ANALYSIS` additionally adds `--kb`; later passes do not.
5. Academic runs (any other profile) are unaffected: `diann_enterprise=false`, `enable_kb` rejected if set, no `--license` unless a path is given.

## Error handling / edge cases

- `--enable_kb` on a non-Enterprise profile → hard error before execution.
- `--diann_license` path missing → `checkIfExists` fails fast at channel creation.
- `--diann_license` unset on Enterprise → allowed (next-to-binary fallback); warn if `--enable_kb` is also set.
- `--skip_preliminary_analysis` → no first-pass search runs, so `--kb` has no effect (document; not an error).

## Testing

- **Guard unit/behavior:** `--enable_kb` without `diann_enterprise` errors with the expected message; with the Enterprise profile it is accepted.
- **Command assembly:** with the Enterprise profile + `--enable_kb` + `--diann_license`, the `PRELIMINARY_ANALYSIS` `.command.sh` contains both `--kb` and `--license`; `FINAL_QUANTIFICATION`/`INDIVIDUAL_ANALYSIS` contain `--license` but **not** `--kb`; `INSILICO_LIBRARY_GENERATION`/`ASSEMBLE_EMPIRICAL_LIBRARY` contain neither `--kb`.
- **CI:** a full Enterprise CI run needs the private `diann-enterprise:2.5.1` image and a license key — neither is publicly available, so this can't run in standard CI. Validation is a maintainer-run integration test (a real run with a valid key), documented in the PR. Academic-profile CI must be unaffected.
- **Downstream:** confirm `diann2msstats` (quantms-utils) and pmultiqc tolerate the extra Enterprise report columns; if they select columns by name this is a no-op.

## Files touched

- `conf/diann_versions/v2_5_1_enterprise.config` (new)
- `nextflow.config` — register `diann_v2_5_1_enterprise` profile; add `diann_enterprise`, `enable_kb`, `diann_license` defaults
- `lib/` guards live in `workflows/dia.nf` (existing guard block)
- `modules/local/diann/preliminary_analysis/main.nf` — `--kb` + `--license`, optional license input
- `modules/local/diann/{individual_analysis,assemble_empirical_library,final_quantification,insilico_library_generation,fine_tune_models}/main.nf` — optional license input + `--license`
- `workflows/dia.nf` — build `ch_diann_license`, pass to DIA-NN processes, add guards
- `nextflow_schema.json` — `diann_enterprise`, `enable_kb`, `diann_license`
- `docs/usage.md` (Enterprise section), `docs/parameters.md`, `README.md` (support table row), `CHANGELOG.md`
