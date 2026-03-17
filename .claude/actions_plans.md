# quantmsdiann — Action Plans & Roadmap

> Standalone DIA-NN (DIA) pipeline refactored from quantms.
> Last updated: 2026-03-17

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

- **Files**: `nextflow.config`
- **Action**: Removed `id_only` parameter. Updated manifest name to `bigbio/quantmsdiann` and description to DIA-NN focused. Removed dead PSM_CONVERSION and MSSTATS_LFQ/TMT publishDir rules from shared.config. Removed unused iso/lfq channel mix from quantmsdiann.nf.
- **Status**: [x] DONE

### 1.4 Update documentation

- **Files**: `README.md`, `docs/usage.md`, `docs/output.md`, `AGENTS.md`
- **Action**: Rewrote README with DIA-NN workflow ASCII diagram, supported formats table, quick start, key outputs. Rewrote AGENTS.md focused on DIA-only pipeline. Updated usage.md and output.md to remove LFQ/TMT/DDA references.
- **Status**: [x] DONE

### 1.5 Remove unused modules

- **Action**: Removed `modules/local/msstats/` directory and `bin/msstats_plfq.R`. All remaining modules (diann, openms, pmultiqc, samplesheet_check, sdrf_parsing, utils) are actively used.
- **Status**: [x] DONE

---

## Phase 2 — DIA-NN 2.x Full Support

**Goal**: Make DIA-NN 2.1.0 a first-class citizen, leverage Parquet-native output.

### 2.1 Promote DIA-NN 2.1.0 to default

- **Files**: All `modules/local/diann/*/main.nf`, `nextflow.config`
- **Action**: Update default container from `diann:v1.8.1_cv1` to `diann:2.1.0`. Keep 1.8.1 available as a fallback profile. Run full test suite against 2.1.0.
- **Dependencies**: Verify all 7 DIA-NN modules work with 2.1.0 CLI changes.
- **Effort**: Medium (requires testing)
- **Status**: [ ] TODO

### 2.2 Parquet-native pipeline path

- **Files**: `modules/local/diann/final_quantification/main.nf`, `modules/local/diann/diann_msstats/main.nf`
- **Action**: DIA-NN 2.0+ outputs Parquet natively. Ensure `DIANN_MSSTATS` (`diann2msstats`) handles Parquet input end-to-end. Add Parquet as a first-class output alongside TSV matrices.
- **Effort**: Medium
- **Status**: [ ] TODO

### 2.3 Add decoy reporting test profile

- **Files**: `conf/tests/`
- **Action**: Create `test_dia_decoys.config` that exercises `diann_report_decoys = true`. Add to CI matrix.
- **Effort**: Small
- **Status**: [ ] TODO

### 2.4 DIA-NN version parameter

- **Files**: `nextflow.config`, `nextflow_schema.json`
- **Action**: Add a `diann_version` parameter that switches between container images (1.8.1 vs 2.1.0) without needing separate profiles. Use conditional container selection in modules.
- **Effort**: Medium
- **Status**: [ ] TODO

---

## Phase 3 — Performance & Scalability

**Goal**: Optimize resource usage and execution for large-scale DIA studies.

### 3.1 Smarter pre-analysis file selection

- **Files**: `workflows/dia.nf`
- **Action**: When `random_preanalysis = true`, implement stratified selection (by condition or batch from SDRF metadata) instead of purely random. This produces better empirical libraries for heterogeneous datasets.
- **Effort**: Medium
- **Status**: [ ] TODO

### 3.2 Resource profiling and tuning

- **Files**: `conf/base.config`
- **Action**: Profile actual CPU, memory, and wall-time usage for each DIA-NN step across dataset sizes (10, 50, 200, 1000+ files). Adjust resource labels. Consider dynamic resource allocation based on input file count.
- **Effort**: Medium
- **Status**: [ ] TODO

### 3.3 GPU support profile

- **Files**: `conf/gpu.config` (new), `modules/local/diann/*/main.nf`
- **Action**: DIA-NN supports GPU acceleration. Create a `gpu` profile with NVIDIA container runtime configuration, GPU resource labels (`accelerator` directive), and GPU-enabled DIA-NN container image.
- **Effort**: Medium-Large
- **Status**: [ ] TODO

### 3.4 Improved caching strategy

- **Files**: DIA-NN modules
- **Action**: Evaluate adding `storeDir` for expensive steps (library generation, preliminary analysis) to enable cross-run caching beyond Nextflow's work directory.
- **Effort**: Small
- **Status**: [ ] TODO

---

## Priority Summary

| Priority        | Phase   | Items                 | Timeline             |
| --------------- | ------- | --------------------- | -------------------- |
| **Done**        | Phase 1 | 1.1-1.5 (cleanup)     | Completed 2026-03-17 |
| **Short-term**  | Phase 2 | 2.1-2.4 (DIA-NN 2.x)  | 1-2 weeks            |
| **Medium-term** | Phase 3 | 3.1-3.4 (performance) | 2-4 weeks            |

---

## Decision Log

| Date       | Decision                                         | Rationale                                                                    |
| ---------- | ------------------------------------------------ | ---------------------------------------------------------------------------- |
| 2026-03-17 | Created roadmap from quantms dev comparison      | Align refactoring priorities                                                 |
| 2026-03-17 | Completed Phase 1 cleanup                        | Remove all non-DIA artifacts                                                 |
| 2026-03-17 | Keep DIANN_MSSTATS, remove MSSTATS_LFQ           | Generate MSstats-compatible CSV but don't run MSstats analysis in-pipeline   |
| 2026-03-17 | Removed Phases 4-6 (quantification, QC, interop) | pMultiQC already covers QC; downstream analysis/interop out of scope for now |
