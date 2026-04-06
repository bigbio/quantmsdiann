# quantmsdiann — Action Plans & Roadmap

> Standalone DIA-NN (DIA) pipeline refactored from quantms.
> Last updated: 2026-03-18

---

## Phase 1 — Cleanup & Correctness (COMPLETED)

**Goal**: Remove legacy quantms artifacts that don't belong in a DIA-only pipeline.

### 1.1 Remove non-DIA test profiles from CI

- **Files**: `.github/workflows/ci.yml`, `.github/workflows/extended_ci.yml`
- **Action**: Removed `test_lfq`, `test_tmt`, `test_localize`, `test_dda_id_*`, `test_tmt_corr` from CI matrices. Updated repository reference from `bigbio/quantms` to `bigbio/quantmsdiann`.
- **Status**: [x] DONE

### 1.2 Remove MSstats analysis step

- **Files**: `workflows/dia.nf`, `workflows/quantmsdiann.nf`, `modules/local/msstats/`, `bin/msstats_plfq.R`, `nextflow.config`, `conf/modules/shared.config`
- **Action**: Removed MSSTATS_LFQ module, R script, and all MSstats analysis parameters. Kept DIANN_MSSTATS conversion step (generates MSstats-compatible CSV without running MSstats analysis). Removed MSstats general and LFQ options from nextflow.config.
- **Status**: [x] DONE

### 1.3 Clean parameter schema and config

- **Files**: `nextflow.config`, `nextflow_schema.json`
- **Action**: Removed `id_only` parameter and `statistical_post_processing` schema section. Updated manifest name to `bigbio/quantmsdiann`. Removed dead publishDir rules from shared.config. Created missing nf-core lint files (logos, docs/README.md).
- **Status**: [x] DONE

### 1.4 Update documentation

- **Files**: `README.md`, `docs/usage.md`, `docs/output.md`, `AGENTS.md`
- **Action**: Rewrote README with DIA-NN workflow SVG diagram. Rewrote AGENTS.md for DIA-only. Cleaned docs. Removed 10 legacy quantms images from docs/images/, created `quantmsdiann_workflow.svg`.
- **Status**: [x] DONE

### 1.5 Remove unused modules and files

- **Action**: Removed `modules/local/msstats/`, `bin/msstats_plfq.R`, `.devcontainer/`, `diann_private.yml`. Cleaned all legacy quantms images.
- **Status**: [x] DONE

---

## Phase 1b — Version-Aware Testing Strategy (COMPLETED)

**Goal**: Map each DIA-NN feature to the minimum version that supports it, with conditional CI.

### DIA-NN Version → Feature Matrix

| Version | Key Features | Container |
| ------- | ------------ | --------- |
| **1.8.1** (default) | Core DIA-NN workflow, library-free, .quant caching | `biocontainers/diann:v1.8.1_cv1` (public) |
| **1.9.2** | QuantUMS quantification, Parquet libraries, redesigned NN | `ghcr.io/bigbio/diann:1.9.2` (private, needs build) |
| **2.0** | Parquet output, proteoform confidence, decoy reporting | `ghcr.io/bigbio/diann:2.1.0` (private) |
| **2.1.0** | Native .raw on Linux, latest improvements | `ghcr.io/bigbio/diann:2.1.0` (private) |
| **2.2.0** | Latest release | `ghcr.io/bigbio/diann:latest` (private, needs build) |

### Test Profiles Created

| Profile | Feature Tested | Min DIA-NN | Container |
| ------- | -------------- | ---------- | --------- |
| `test_dia` | Core workflow | 1.8.1 | biocontainers (public) |
| `test_dia_dotd` | Bruker .d format | 1.8.1 | biocontainers (public) |
| `test_dia_quantums` | QuantUMS quantification | 1.9.2 | ghcr.io/bigbio/diann:2.1.0 |
| `test_dia_parquet` | Parquet output + decoys | 2.0 | ghcr.io/bigbio/diann:2.1.0 |
| `test_latest_dia` | Latest version validation | latest | ghcr.io/bigbio/diann:2.1.0 |
| `test_full_dia` | Full-size dataset | 1.8.1 | biocontainers (public) |

### CI/CD Structure

**ci.yml** (every PR, fast):
- `test_dia`, `test_dia_dotd` — public containers, no auth needed

**extended_ci.yml** (5 jobs):
1. **test-default** — always runs `test_dia`, `test_dia_dotd` (Docker, 2 NXF versions)
2. **detect-changes** — uses `dorny/paths-filter` to detect which feature files changed
3. **test-features** — always runs on push to dev/master, releases, manual dispatch: `test_latest_dia`, `test_dia_quantums`, `test_dia_parquet`
4. **test-features-pr** — runs on PRs only when relevant files change (conditional per-feature)
5. **test-singularity** — default tests only, after Docker passes

### Container Build Needed

- **DIA-NN 1.9.2**: Dockerfile created at `quantms-containers/diann-1.9.2/Dockerfile`. Needs to be built and pushed to `ghcr.io/bigbio/diann:1.9.2`.
- **DIA-NN 2.2.0**: Need Dockerfile when ready to test latest.

### Status: [x] DONE

---

## Phase 2 — DIA-NN 2.x Full Support

**Goal**: Make DIA-NN 2.1.0 a first-class citizen, leverage Parquet-native output.

### 2.1 Promote DIA-NN 2.1.0 to default

- **Files**: All `modules/local/diann/*/main.nf`, `nextflow.config`
- **Action**: Update default container from `diann:v1.8.1_cv1` to `diann:2.1.0`. Keep 1.8.1 available as a fallback profile.
- **Dependencies**: Verify all 7 DIA-NN modules work with 2.1.0 CLI changes.
- **Effort**: Medium
- **Status**: [ ] TODO

### 2.2 Parquet-native pipeline path

- **Files**: `modules/local/diann/final_quantification/main.nf`, `modules/local/diann/diann_msstats/main.nf`
- **Action**: Ensure DIANN_MSSTATS handles Parquet input end-to-end. Validated by `test_dia_parquet` CI profile.
- **Effort**: Medium
- **Status**: [ ] TODO

### 2.3 DIA-NN version parameter

- **Files**: `nextflow.config`, `nextflow_schema.json`
- **Action**: Add a `diann_version` parameter that switches container images without needing separate profiles.
- **Effort**: Medium
- **Status**: [ ] TODO

---

## Phase 3 — Performance & Scalability

**Goal**: Optimize resource usage and execution for large-scale DIA studies.

### 3.1 Smarter pre-analysis file selection

- **Files**: `workflows/dia.nf`
- **Action**: Implement stratified selection (by condition/batch from SDRF) instead of purely random.
- **Effort**: Medium
- **Status**: [ ] TODO

### 3.2 Resource profiling and tuning

- **Files**: `conf/base.config`
- **Action**: Profile resource usage across dataset sizes. Adjust labels. Consider dynamic allocation.
- **Effort**: Medium
- **Status**: [ ] TODO

### 3.3 GPU support profile

- **Files**: `conf/gpu.config` (new), `modules/local/diann/*/main.nf`
- **Action**: Create `gpu` profile with NVIDIA runtime, `accelerator` directives, GPU container.
- **Effort**: Medium-Large
- **Status**: [ ] TODO

### 3.4 Improved caching strategy

- **Files**: DIA-NN modules
- **Action**: Evaluate `storeDir` for expensive steps (library generation, preliminary analysis).
- **Effort**: Small
- **Status**: [ ] TODO

---

## Priority Summary

| Priority        | Phase    | Items                       | Timeline             |
| --------------- | -------- | --------------------------- | -------------------- |
| **Done**        | Phase 1  | 1.1-1.5 (cleanup)           | Completed 2026-03-17 |
| **Done**        | Phase 1b | Version-aware testing        | Completed 2026-03-18 |
| **Short-term**  | Phase 2  | 2.1-2.3 (DIA-NN 2.x)        | 1-2 weeks            |
| **Medium-term** | Phase 3  | 3.1-3.4 (performance)       | 2-4 weeks            |

---

## Decision Log

| Date       | Decision                                         | Rationale                                                                    |
| ---------- | ------------------------------------------------ | ---------------------------------------------------------------------------- |
| 2026-03-17 | Created roadmap from quantms dev comparison      | Align refactoring priorities                                                 |
| 2026-03-17 | Completed Phase 1 cleanup                        | Remove all non-DIA artifacts                                                 |
| 2026-03-17 | Keep DIANN_MSSTATS, remove MSSTATS_LFQ           | Generate MSstats-compatible CSV but don't run MSstats analysis in-pipeline   |
| 2026-03-17 | Removed Phases 4-6 (quantification, QC, interop) | pmultiqc already covers QC; downstream analysis/interop out of scope for now |
| 2026-03-18 | Version-aware testing with conditional CI         | Each feature maps to min DIA-NN version; PRs only run affected feature tests |
| 2026-03-18 | DIA-NN containers are private (license)           | Academic-only license; GHCR_USERNAME + GHCR_TOKEN secrets required           |
| 2026-03-18 | Created DIA-NN 1.9.2 Dockerfile                  | Needed for QuantUMS feature testing at minimum supported version             |
