# quantmsdiann v1.0.0 Release Roadmap — Design Spec

**Date:** 2026-04-03
**Author:** Yasset Perez-Riverol + Claude
**Status:** Approved
**Issues covered:** #1, #2, #3, #5, #7, #9, #10, #15, #17

---

## Overview

Comprehensive pre-release work for quantmsdiann v1.0.0 covering robustness fixes, DDA support via DIA-NN 2.3.2, new feature parameters, and documentation. Four-week timeline.

## Architecture

No new workflows or modules. The existing `workflows/dia.nf` pipeline handles both DIA and DDA since DIA-NN uses the same steps with `--dda` appended. Default container stays 1.8.1; 2.3.2 is the "latest" option.

```
SDRF_PARSING -> FILE_PREPARATION -> INSILICO_LIBRARY -> PRELIMINARY_ANALYSIS ->
ASSEMBLE_EMPIRICAL -> INDIVIDUAL_ANALYSIS -> FINAL_QUANTIFICATION -> DIANN_MSSTATS -> PMULTIQC
```

DDA parallelization is identical to DIA — per-file parallel for PRELIMINARY_ANALYSIS and INDIVIDUAL_ANALYSIS, synchronization points at ASSEMBLE_EMPIRICAL and FINAL_QUANTIFICATION. Confirmed by DIA-NN author in vdemichev/DiaNN#1727.

---

## Week 1: Robustness Fixes

### 1.1 Fix tee pipes masking failures

Add `set -o pipefail` or `exit ${PIPESTATUS[0]}` to script blocks in:

- `modules/local/diann/generate_cfg/main.nf`
- `modules/local/diann/diann_msstats/main.nf`
- `modules/local/samplesheet_check/main.nf`
- `modules/local/sdrf_parsing/main.nf`

**Risk:** Without this fix, if `quantmsutilsc` or `parse_sdrf` fails, the Nextflow task appears to succeed because `tee` returns exit code 0.

### 1.2 Add error retry to long-running DIA-NN tasks

Add `label 'error_retry'` to:

- PRELIMINARY_ANALYSIS (process_high)
- INDIVIDUAL_ANALYSIS (process_high)
- FINAL_QUANTIFICATION (process_high)
- INSILICO_LIBRARY_GENERATION (process_medium)
- ASSEMBLE_EMPIRICAL_LIBRARY (process_medium)

These are the longest-running tasks and most susceptible to transient failures (OOM, I/O timeouts).

### 1.3 Empty input guards

- `subworkflows/local/create_input_channel/main.nf` — Fail fast if SDRF has 0 data rows after `splitCsv`. Add a `.count()` check with error message.
- `workflows/dia.nf` — Guard `.first()` calls on `ch_searchdb` and `ch_experiment_meta` with `.ifEmpty { error("...") }` to prevent indefinite hangs on empty inputs.

### 1.4 New test configs

**`conf/tests/test_dia_skip_preanalysis.config`:**

- Sets `skip_preliminary_analysis = true`
- Uses default `mass_acc_ms1`, `mass_acc_ms2`, `scan_window` params
- Same PXD026600 test data as test_dia
- Validates the skip path that is currently untested in CI

**`conf/tests/test_dia_speclib.config`:**

- Sets `diann_speclib` to a pre-built spectral library
- Skips INSILICO_LIBRARY_GENERATION (the `if` branch in dia.nf line 55-56)
- Requires a small test spectral library in quantms-test-datasets (or generated from existing test data)

Both configs added to `extended_ci.yml` stage 2a.

---

## Week 2: Container Build + DDA Support

### 2.1 Container (PR to bigbio/quantms-containers)

Build and push `ghcr.io/bigbio/diann:2.3.2` from existing Dockerfile at `quantms-containers/diann-2.3.2/Dockerfile`. The Dockerfile downloads `DIA-NN-2.3.2-Academia-Linux.zip` from the official GitHub release.

### 2.2 Version config

Add `conf/diann_versions/v2_3_2.config`:

```groovy
params.diann_version = '2.3.2'
process {
    withLabel: diann {
        container = 'ghcr.io/bigbio/diann:2.3.2'
    }
}
singularity.enabled = false
docker.enabled = true
```

Add profile in `nextflow.config`:

```groovy
diann_v2_3_2 { includeConfig 'conf/diann_versions/v2_3_2.config' }
```

### 2.3 DDA implementation

**New param** in `nextflow.config`:

```groovy
diann_dda = false  // Enable DDA analysis mode (requires DIA-NN >= 2.3.2)
```

**Version guard** in `workflows/dia.nf` at workflow start:

```groovy
if (params.diann_dda && params.diann_version < '2.3.2') {
    error("DDA mode requires DIA-NN >= 2.3.2. Current version: ${params.diann_version}. Use -profile diann_v2_3_2")
}
```

**Pass `--dda` to all DIA-NN modules** — In each module's script block, add:

```groovy
diann_dda_flag = params.diann_dda ? "--dda" : ""
```

And append `${diann_dda_flag}` to the DIA-NN command. Add `'--dda'` to the `blocked` list in all 5 modules.

**Accept DDA in create_input_channel** — Modify `create_input_channel/main.nf` lines 78-88:

```groovy
if (acqMethod.toLowerCase().contains("data-independent acquisition") || acqMethod.toLowerCase().contains("dia")) {
    meta.acquisition_method = "dia"
} else if (params.diann_dda && (acqMethod.toLowerCase().contains("data-dependent acquisition") || acqMethod.toLowerCase().contains("dda"))) {
    meta.acquisition_method = "dda"
} else if (acqMethod.isEmpty()) {
    meta.acquisition_method = params.diann_dda ? "dda" : "dia"
} else {
    log.error("Unsupported acquisition method: '${acqMethod}'. ...")
    exit(1)
}
```

### 2.4 Test data (PR to bigbio/quantms-test-datasets)

Add `comment[proteomics data acquisition method]` column with value `NT=Data-Dependent Acquisition;AC=PRIDE:0000627` to `testdata/lfq_ci/BSA/BSA_design.sdrf.tsv`. The sdrf-pipelines `convert-diann` already extracts this column correctly — no sdrf-pipelines changes needed.

### 2.5 Test config

**`conf/tests/test_dda.config`:**

- Points to BSA dataset from `bigbio/quantms-test-datasets/testdata/lfq_ci/BSA/`
- Sets `diann_dda = true`
- Pins to `ghcr.io/bigbio/diann:2.3.2`
- Added to `extended_ci.yml` stage 2a (private containers)

### 2.6 Schema + blocked list

- Add `diann_dda` to `nextflow_schema.json` with description and version note
- Add `'--dda'` to blocked lists in all 5 DIA-NN modules

---

## Week 3: Features

### 3.1 New DIA-NN parameters

| Parameter              | Flag               | Min Version | Module                      | Default         |
| ---------------------- | ------------------ | ----------- | --------------------------- | --------------- |
| `diann_light_models`   | `--light-models`   | 2.0         | INSILICO_LIBRARY_GENERATION | false           |
| `diann_export_quant`   | `--export-quant`   | 2.0         | FINAL_QUANTIFICATION        | false           |
| `diann_read_threads`   | `--read-threads N` | 2.0         | All DIA-NN steps            | null (disabled) |
| `diann_site_ms1_quant` | `--site-ms1-quant` | 2.0         | FINAL_QUANTIFICATION        | false           |

Each parameter: add to `nextflow.config`, `nextflow_schema.json`, module script block (with version guard where needed), and module blocked list.

### 3.2 InfinDIA groundwork (issue #10)

New params:

- `enable_infin_dia` (boolean, default: false) — requires >= 2.3.0
- `diann_pre_select` (integer, optional) — `--pre-select N` precursor limit

Implementation:

- Pass `--infin-dia` to INSILICO_LIBRARY_GENERATION when enabled
- Version guard: error if enabled with DIA-NN < 2.3.0
- No test config — InfinDIA needs large databases to be meaningful
- Document as experimental/advanced feature

### 3.3 Close resolved issues

- **#17** (phospho monitor-mod) — Already implemented via `diann_config.cfg` extraction. Close with explanation.
- **#2** (param consolidation) — Superseded by #4 (Phase 6). Close as duplicate.
- **#3** (ext.args documentation) — Close with documentation update in Week 4.

---

## Week 4: Documentation

### 4.1 Create `docs/parameters.md`

Comprehensive parameter reference with all ~70 params grouped by:

- Input/output options
- File preparation (conversion, indexing, statistics)
- DIA-NN general settings
- Mass accuracy and calibration
- Library generation
- Quantification and output
- DDA mode
- InfinDIA (experimental)
- Quality control (pmultiqc)
- MultiQC options
- Boilerplate (nf-core standard)

Each param: name, type, default, description, version requirement (if any).

### 4.2 Complete `docs/usage.md`

Add missing sections:

- Preprocessing params (`reindex_mzml`, `mzml_statistics`, `convert_dotd`)
- QC params (`enable_pmultiqc`, `skip_table_plots`, `contaminant_string`)
- MultiQC options
- DDA mode with limitations
- InfinDIA (basic)
- `diann_extra_args` scope per module (closes #3)
- `--verbose_modules` profile
- Container version override guide (closes #9)
- Singularity usage with image caching
- SLURM example (from `pride_codon_slurm.config`)
- AWS/cloud basics (Wave profile)

### 4.3 Update `docs/output.md`

- Intermediate outputs under `--verbose_modules`
- Parquet vs TSV output explanation (DIA-NN 2.0+)
- MSstats format section

### 4.4 Housekeeping

- Add pmultiqc to `CITATIONS.md`
- Fix #15 (docs mismatch for `--input`)
- Update README with DIA-NN version table and link to parameter reference
- Close #1 (documentation issue), #9 (container docs), #15 (input mismatch)

---

## Issues Status After Release

| Issue | Status           | Resolution                                           |
| ----- | ---------------- | ---------------------------------------------------- |
| #1    | Closed           | Parameter documentation created                      |
| #2    | Closed           | Superseded by #4                                     |
| #3    | Closed           | ext.args scope documented                            |
| #5    | Closed           | DDA support implemented                              |
| #7    | Closed           | Phase 2 features wired                               |
| #9    | Closed           | Container docs added                                 |
| #10   | Partially closed | InfinDIA groundwork done, full support needs testing |
| #15   | Closed           | Docs mismatch fixed                                  |
| #17   | Closed           | Already implemented                                  |
| #4    | Open             | Blocked on sdrf-pipelines converter release          |
| #6    | Open             | Blocked on PRIDE ontology release                    |
| #25   | Open             | QPX deferred to next release                         |

---

## External PRs Required

1. **bigbio/quantms-containers** — Build and push `ghcr.io/bigbio/diann:2.3.2`
2. **bigbio/quantms-test-datasets** — Add `comment[proteomics data acquisition method]` column to BSA SDRF

---

## Success Criteria

- `nf-core pipelines lint --release` passes with 0 failures
- `pre-commit run --all-files` passes
- All existing CI tests still pass (test_dia, test_dia_dotd, etc.)
- New tests pass: test_dia_skip_preanalysis, test_dia_speclib, test_dda
- DDA test completes with BSA dataset on DIA-NN 2.3.2
- `docs/parameters.md` covers all params in `nextflow_schema.json`
- `docs/usage.md` covers all major use cases
