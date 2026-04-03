# quantmsdiann v1.0.0 Release — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare quantmsdiann for a robust v1.0.0 release with DDA support, new DIA-NN parameters, and comprehensive documentation.

**Architecture:** No new workflows or modules. All changes are additions to existing files — new params, flags, guards, test configs, and docs. DDA uses the same pipeline as DIA with `--dda` appended to all DIA-NN invocations. Default container stays 1.8.1; 2.3.2 is opt-in via profile.

**Tech Stack:** Nextflow DSL2, nf-core, DIA-NN, Groovy, Bash

---

## Task 1: Fix tee pipes masking failures

**Files:**
- Modify: `modules/local/diann/generate_cfg/main.nf:26`
- Modify: `modules/local/diann/diann_msstats/main.nf:21-26`
- Modify: `modules/local/samplesheet_check/main.nf:38-43`
- Modify: `modules/local/sdrf_parsing/main.nf:24-30`

- [ ] **Step 1: Add pipefail to generate_cfg**

In `modules/local/diann/generate_cfg/main.nf`, find the `"""` opening the script block (line 20) and add `set -o pipefail` as the first line:

```groovy
    """
    set -o pipefail
    parse_sdrf generate-diann-cfg \\
    ...
    ```

- [ ] **Step 2: Add pipefail to diann_msstats**

In `modules/local/diann/diann_msstats/main.nf`, find the `"""` opening the script block (line 20) and add `set -o pipefail`:

```groovy
    """
    set -o pipefail
    quantmsutilsc diann2msstats \\
    ...
    ```

- [ ] **Step 3: Add pipefail to samplesheet_check**

In `modules/local/samplesheet_check/main.nf`, find the `"""` opening the script block and add `set -o pipefail`:

```groovy
    """
    set -o pipefail
    ...
    ```

- [ ] **Step 4: Add pipefail to sdrf_parsing**

In `modules/local/sdrf_parsing/main.nf`, find the `"""` opening the script block (line 22) and add `set -o pipefail`:

```groovy
    """
    set -o pipefail
    parse_sdrf convert-diann \\
    ...
    ```

- [ ] **Step 5: Validate and commit**

```bash
conda run -n nfcore pre-commit run --all-files
git add modules/local/diann/generate_cfg/main.nf modules/local/diann/diann_msstats/main.nf modules/local/samplesheet_check/main.nf modules/local/sdrf_parsing/main.nf
git commit -m "fix: add pipefail to all modules with tee pipes

Without pipefail, if the command before tee fails, tee returns 0 and
the Nextflow task appears to succeed. This masked failures in
generate_cfg, diann_msstats, samplesheet_check, and sdrf_parsing."
```

---

## Task 2: Add error retry to long-running DIA-NN tasks

**Files:**
- Modify: `modules/local/diann/preliminary_analysis/main.nf:3-4`
- Modify: `modules/local/diann/individual_analysis/main.nf:3-4`
- Modify: `modules/local/diann/final_quantification/main.nf:3-4`
- Modify: `modules/local/diann/insilico_library_generation/main.nf:3-4`
- Modify: `modules/local/diann/assemble_empirical_library/main.nf:3-4`

- [ ] **Step 1: Add error_retry label to all 5 DIA-NN modules**

In each file, add `label 'error_retry'` after the existing labels. For example, `preliminary_analysis/main.nf` currently has:

```groovy
    label 'process_high'
    label 'diann'
```

Change to:

```groovy
    label 'process_high'
    label 'diann'
    label 'error_retry'
```

Do the same for:
- `individual_analysis/main.nf` (after `label 'diann'`)
- `final_quantification/main.nf` (after `label 'diann'`)
- `insilico_library_generation/main.nf` (after `label 'diann'`)
- `assemble_empirical_library/main.nf` (after `label 'diann'`)

- [ ] **Step 2: Validate and commit**

```bash
conda run -n nfcore pre-commit run --all-files
git add modules/local/diann/preliminary_analysis/main.nf modules/local/diann/individual_analysis/main.nf modules/local/diann/final_quantification/main.nf modules/local/diann/insilico_library_generation/main.nf modules/local/diann/assemble_empirical_library/main.nf
git commit -m "fix: add error_retry label to all DIA-NN analysis modules

These are the longest-running tasks and most susceptible to transient
failures (OOM, I/O timeouts). The error_retry label enables automatic
retry on signal exits (130-145, 104, 175)."
```

---

## Task 3: Add empty input guards

**Files:**
- Modify: `workflows/dia.nf:38,46`

- [ ] **Step 1: Guard ch_searchdb with ifEmpty**

In `workflows/dia.nf`, line 38, change:

```groovy
    ch_searchdb = channel.fromPath(params.database, checkIfExists: true).first()
```

To:

```groovy
    ch_searchdb = channel.fromPath(params.database, checkIfExists: true)
        .ifEmpty { error("No protein database found at '${params.database}'. Provide --database <path/to/proteins.fasta>") }
        .first()
```

- [ ] **Step 2: Guard ch_experiment_meta with ifEmpty**

In `workflows/dia.nf`, line 46, change:

```groovy
    ch_experiment_meta = ch_result.meta.unique { m -> m.experiment_id }.first()
```

To:

```groovy
    ch_experiment_meta = ch_result.meta.unique { m -> m.experiment_id }
        .ifEmpty { error("No valid input files found after SDRF parsing. Check your SDRF file and input paths.") }
        .first()
```

- [ ] **Step 3: Validate and commit**

```bash
conda run -n nfcore pre-commit run --all-files
git add workflows/dia.nf
git commit -m "fix: add empty input guards to prevent silent pipeline hangs

Guard ch_searchdb and ch_experiment_meta with ifEmpty to fail fast
with clear error messages instead of hanging indefinitely."
```

---

## Task 4: Add DIA-NN 2.3.2 version config and profile

**Files:**
- Create: `conf/diann_versions/v2_3_2.config`
- Modify: `nextflow.config:245-247` (profiles section)

- [ ] **Step 1: Create v2_3_2.config**

Create `conf/diann_versions/v2_3_2.config`:

```groovy
/*
 * DIA-NN 2.3.2 container override (private ghcr.io)
 * Latest release with DDA support and InfinDIA.
 */
params.diann_version = '2.3.2'

process {
    withLabel: diann {
        container = 'ghcr.io/bigbio/diann:2.3.2'
    }
}

singularity.enabled = false
docker.enabled = true
```

- [ ] **Step 2: Add profile to nextflow.config**

In `nextflow.config`, after the `diann_v2_2_0` profile line (around line 247), add:

```groovy
    diann_v2_3_2        { includeConfig 'conf/diann_versions/v2_3_2.config'    }
```

- [ ] **Step 3: Validate and commit**

```bash
conda run -n nfcore pre-commit run --all-files
git add conf/diann_versions/v2_3_2.config nextflow.config
git commit -m "feat: add DIA-NN 2.3.2 version config and profile

Adds conf/diann_versions/v2_3_2.config with ghcr.io/bigbio/diann:2.3.2
container. Use -profile diann_v2_3_2 to opt in. Default stays 1.8.1.
Enables DDA support and InfinDIA features."
```

---

## Task 5: Implement DDA support — params, version guard, flag passthrough

**Files:**
- Modify: `nextflow.config:53-57` (DIA-NN general params)
- Modify: `nextflow_schema.json` (DIA-NN section)
- Modify: `workflows/dia.nf:35-38` (version guard)
- Modify: `subworkflows/local/create_input_channel/main.nf:75-88` (acquisition method)
- Modify: `modules/local/diann/insilico_library_generation/main.nf` (blocked list + flag)
- Modify: `modules/local/diann/preliminary_analysis/main.nf` (blocked list + flag)
- Modify: `modules/local/diann/assemble_empirical_library/main.nf` (blocked list + flag)
- Modify: `modules/local/diann/individual_analysis/main.nf` (blocked list + flag)
- Modify: `modules/local/diann/final_quantification/main.nf` (blocked list + flag)

- [ ] **Step 1: Add diann_dda param to nextflow.config**

In `nextflow.config`, after `diann_extra_args = null` (line 57), add:

```groovy
    diann_dda               = false  // Enable DDA analysis mode (requires DIA-NN >= 2.3.2)
```

- [ ] **Step 2: Add diann_dda to nextflow_schema.json**

In `nextflow_schema.json`, in the DIA-NN section (inside `"$defs"` > appropriate group), add:

```json
"diann_dda": {
    "type": "boolean",
    "description": "Enable DDA (Data-Dependent Acquisition) analysis mode. Passes --dda to all DIA-NN steps. Requires DIA-NN >= 2.3.2 (use -profile diann_v2_3_2). Beta feature — only trust q-values, PEP, RT/IM, Ms1.Apex.Area. PTM localization unreliable with DDA.",
    "fa_icon": "fas fa-flask",
    "default": false
}
```

Add `"diann_dda"` to the corresponding `"required"` or `"properties"` list in the appropriate group.

- [ ] **Step 3: Add version guard in workflows/dia.nf**

In `workflows/dia.nf`, at the start of the `main:` block (after line 37), add:

```groovy
    // Version guard for DDA mode
    if (params.diann_dda && params.diann_version < '2.3.2') {
        error("DDA mode (--diann_dda) requires DIA-NN >= 2.3.2. Current version: ${params.diann_version}. Use -profile diann_v2_3_2")
    }
```

- [ ] **Step 4: Accept DDA acquisition method in create_input_channel**

In `subworkflows/local/create_input_channel/main.nf`, replace lines 75-88 (the acquisition method validation block):

```groovy
    // Validate acquisition method
    def acqMethod = row.AcquisitionMethod?.toString()?.trim() ?: ""
    if (acqMethod.toLowerCase().contains("data-independent acquisition") || acqMethod.toLowerCase().contains("dia")) {
        meta.acquisition_method = "dia"
    } else if (params.diann_dda && (acqMethod.toLowerCase().contains("data-dependent acquisition") || acqMethod.toLowerCase().contains("dda"))) {
        meta.acquisition_method = "dda"
    } else if (acqMethod.isEmpty()) {
        meta.acquisition_method = params.diann_dda ? "dda" : "dia"
    } else {
        log.error("Unsupported acquisition method: '${acqMethod}'. This pipeline supports DIA" + (params.diann_dda ? " and DDA (--diann_dda)" : "") + ". Found in file: ${filestr}")
        exit(1)
    }
```

- [ ] **Step 5: Add --dda flag to all 5 DIA-NN modules**

For each of the 5 DIA-NN modules, make two changes:

**a) Add `'--dda'` to the blocked list.** In each module's `def blocked = [...]`, add `'--dda'` to the array.

**b) Add the flag variable and append it to the command.** In each module's script block, after the existing flag variables (before the `"""` shell block), add:

```groovy
    diann_dda_flag = params.diann_dda ? "--dda" : ""
```

Then append `${diann_dda_flag} \\` to the DIA-NN command, before `\${mod_flags}` (or before `$args` if no mod_flags).

Apply to:
- `modules/local/diann/insilico_library_generation/main.nf`
- `modules/local/diann/preliminary_analysis/main.nf`
- `modules/local/diann/assemble_empirical_library/main.nf`
- `modules/local/diann/individual_analysis/main.nf`
- `modules/local/diann/final_quantification/main.nf`

- [ ] **Step 6: Validate and commit**

```bash
conda run -n nfcore pre-commit run --all-files
conda run -n nfcore nf-core pipelines lint --dir .
git add nextflow.config nextflow_schema.json workflows/dia.nf subworkflows/local/create_input_channel/main.nf modules/local/diann/*/main.nf
git commit -m "feat: add DDA support via --diann_dda flag (#5)

- New param diann_dda (boolean, default: false)
- Version guard: requires DIA-NN >= 2.3.2
- Passes --dda to all 5 DIA-NN modules when enabled
- Accepts DDA acquisition method in SDRF when diann_dda=true
- Added --dda to blocked lists in all modules

Closes #5"
```

---

## Task 6: Add DDA test config

**Files:**
- Create: `conf/tests/test_dda.config`
- Modify: `.github/workflows/extended_ci.yml:110-191` (stage 2a)

- [ ] **Step 1: Create test_dda.config**

Create `conf/tests/test_dda.config`:

```groovy
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Nextflow config file for testing DDA analysis (requires DIA-NN >= 2.3.2)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Tests DDA mode using the BSA dataset with --diann_dda flag.
    Uses ghcr.io/bigbio/diann:2.3.2.

    Use as follows:
        nextflow run bigbio/quantmsdiann -profile test_dda,docker [--outdir <OUTDIR>]

------------------------------------------------------------------------------------------------
*/

process {
    resourceLimits = [
        cpus: 4,
        memory: '12.GB',
        time: '48.h'
    ]
}

params {
    config_profile_name        = 'Test profile for DDA analysis'
    config_profile_description = 'DDA test using BSA dataset with DIA-NN 2.3.2.'

    outdir = './results_dda'

    // Input data — BSA DDA dataset
    input = 'https://raw.githubusercontent.com/bigbio/quantms-test-datasets/quantms/testdata/lfq_ci/BSA/BSA_design.sdrf.tsv'
    database = 'https://raw.githubusercontent.com/bigbio/quantms-test-datasets/quantms/testdata/lfq_ci/BSA/18Protein_SoCe_Tr_detergents_trace.fasta'

    // DDA mode
    diann_dda = true

    // Search parameters matching BSA dataset
    min_peptide_length = 7
    max_peptide_length = 30
    max_precursor_charge = 3
    allowed_missed_cleavages = 1
    diann_normalize = false
    publish_dir_mode = 'symlink'
    max_mods = 2
}

process {
    withLabel: diann {
        container = 'ghcr.io/bigbio/diann:2.3.2'
    }
}

singularity.enabled = false
docker.enabled = true
```

- [ ] **Step 2: Add test_dda profile to nextflow.config**

In `nextflow.config`, after the `test_dia_2_2_0` profile line (around line 241), add:

```groovy
    test_dda            { includeConfig 'conf/tests/test_dda.config'           }
```

- [ ] **Step 3: Add test_dda to extended_ci.yml stage 2a**

In `.github/workflows/extended_ci.yml`, in the `test-latest` job matrix (around line 120), add `"test_dda"` to the `test_profile` array:

```yaml
        test_profile: ["test_latest_dia", "test_dia_quantums", "test_dia_parquet", "test_dda"]
```

- [ ] **Step 4: Validate and commit**

```bash
conda run -n nfcore pre-commit run --all-files
git add conf/tests/test_dda.config nextflow.config .github/workflows/extended_ci.yml
git commit -m "test: add DDA test config using BSA dataset with DIA-NN 2.3.2

Uses bigbio/quantms-test-datasets BSA LFQ dataset (~34 MB) with
diann_dda=true pinned to ghcr.io/bigbio/diann:2.3.2. Added to
extended_ci.yml stage 2a (private containers)."
```

---

## Task 7: Add test configs for skip_preliminary_analysis and speclib input

**Files:**
- Create: `conf/tests/test_dia_skip_preanalysis.config`
- Modify: `nextflow.config` (profiles section)
- Modify: `.github/workflows/extended_ci.yml` (stage 2a)

- [ ] **Step 1: Create test_dia_skip_preanalysis.config**

Create `conf/tests/test_dia_skip_preanalysis.config`:

```groovy
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Nextflow config file for testing skip_preliminary_analysis path
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Tests the pipeline with skip_preliminary_analysis=true, using default
    mass accuracy parameters. Validates the untested code path in dia.nf.

    Use as follows:
        nextflow run bigbio/quantmsdiann -profile test_dia_skip_preanalysis,docker [--outdir <OUTDIR>]

------------------------------------------------------------------------------------------------
*/

process {
    resourceLimits = [
        cpus: 4,
        memory: '12.GB',
        time: '48.h'
    ]
}

params {
    config_profile_name        = 'Test profile for skip preliminary analysis'
    config_profile_description = 'Tests skip_preliminary_analysis path with default mass accuracy params.'

    outdir = './results_skip_preanalysis'

    // Input data — same as test_dia
    input = 'https://raw.githubusercontent.com/bigbio/quantms-test-datasets/quantms/testdata/dia_ci/PXD026600.sdrf.tsv'
    database = 'https://raw.githubusercontent.com/bigbio/quantms-test-datasets/quantms/testdata/dia_ci/REF_EColi_K12_UPS1_combined.fasta'
    min_pr_mz = 350
    max_pr_mz = 950
    min_fr_mz = 500
    max_fr_mz = 1500
    min_peptide_length = 15
    max_peptide_length = 30
    max_precursor_charge = 3
    allowed_missed_cleavages = 1
    diann_normalize = false
    publish_dir_mode = 'symlink'
    max_mods = 2

    // Skip preliminary analysis — use default mass accuracy params
    skip_preliminary_analysis = true
    mass_acc_ms2 = 15
    mass_acc_ms1 = 15
    scan_window = 8
}
```

- [ ] **Step 2: Add profile to nextflow.config**

After existing test profiles (around line 242), add:

```groovy
    test_dia_skip_preanalysis { includeConfig 'conf/tests/test_dia_skip_preanalysis.config' }
```

- [ ] **Step 3: Add to extended_ci.yml stage 2a**

In the `test-latest` job matrix, add `"test_dia_skip_preanalysis"` to the `test_profile` array.

- [ ] **Step 4: Validate and commit**

```bash
conda run -n nfcore pre-commit run --all-files
git add conf/tests/test_dia_skip_preanalysis.config nextflow.config .github/workflows/extended_ci.yml
git commit -m "test: add test config for skip_preliminary_analysis path

Tests the previously untested code path where preliminary analysis is
skipped and default mass accuracy parameters are used directly."
```

---

## Task 8: Add new DIA-NN feature parameters (light-models, export-quant, site-ms1-quant)

**Files:**
- Modify: `nextflow.config` (params section)
- Modify: `nextflow_schema.json`
- Modify: `modules/local/diann/insilico_library_generation/main.nf` (light-models)
- Modify: `modules/local/diann/final_quantification/main.nf` (export-quant, site-ms1-quant)

- [ ] **Step 1: Add params to nextflow.config**

In `nextflow.config`, in the DIA-NN general section (after `diann_dda`, around line 58), add:

```groovy
    diann_light_models      = false  // add '--light-models' for 10x faster library generation (DIA-NN >= 2.0)
    diann_export_quant      = false  // add '--export-quant' for fragment-level parquet export (DIA-NN >= 2.0)
    diann_site_ms1_quant    = false  // add '--site-ms1-quant' for MS1 apex PTM quantification (DIA-NN >= 2.0)
```

- [ ] **Step 2: Add params to nextflow_schema.json**

Add each param to the DIA-NN section in the schema with type, description, default, and fa_icon.

- [ ] **Step 3: Wire --light-models in insilico_library_generation**

In `modules/local/diann/insilico_library_generation/main.nf`:

a) Add `'--light-models'` to the blocked list (line 26-32).

b) After `diann_no_peptidoforms` variable (line 47), add:

```groovy
    diann_light_models = params.diann_light_models ? "--light-models" : ""
```

c) Append `${diann_light_models} \\` to the DIA-NN command before `${met_excision}`.

- [ ] **Step 4: Wire --export-quant and --site-ms1-quant in final_quantification**

In `modules/local/diann/final_quantification/main.nf`:

a) Add `'--export-quant'` and `'--site-ms1-quant'` to the blocked list (line 45-50).

b) After `diann_dda_flag` variable, add:

```groovy
    diann_export_quant = params.diann_export_quant ? "--export-quant" : ""
    diann_site_ms1_quant = params.diann_site_ms1_quant ? "--site-ms1-quant" : ""
```

c) Append both to the DIA-NN command before `\${mod_flags}`.

- [ ] **Step 5: Validate and commit**

```bash
conda run -n nfcore pre-commit run --all-files
conda run -n nfcore nf-core pipelines lint --dir .
git add nextflow.config nextflow_schema.json modules/local/diann/insilico_library_generation/main.nf modules/local/diann/final_quantification/main.nf
git commit -m "feat: add --light-models, --export-quant, --site-ms1-quant params (#7)

- diann_light_models: 10x faster in-silico library generation
- diann_export_quant: fragment-level parquet export
- diann_site_ms1_quant: MS1 apex intensities for PTM quantification
All require DIA-NN >= 2.0."
```

---

## Task 9: Add InfinDIA groundwork

**Files:**
- Modify: `nextflow.config` (params section)
- Modify: `nextflow_schema.json`
- Modify: `workflows/dia.nf` (version guard)
- Modify: `modules/local/diann/insilico_library_generation/main.nf` (flag)

- [ ] **Step 1: Add InfinDIA params to nextflow.config**

After the DDA param, add:

```groovy
    // DIA-NN: InfinDIA (experimental, v2.3.0+)
    enable_infin_dia        = false  // Enable InfinDIA for ultra-large search spaces
    diann_pre_select        = null   // --pre-select N precursor limit for InfinDIA
```

- [ ] **Step 2: Add to nextflow_schema.json**

Add `enable_infin_dia` (boolean) and `diann_pre_select` (integer, optional) to the schema.

- [ ] **Step 3: Add version guard in workflows/dia.nf**

After the DDA version guard, add:

```groovy
    if (params.enable_infin_dia && params.diann_version < '2.3.0') {
        error("InfinDIA requires DIA-NN >= 2.3.0. Current version: ${params.diann_version}. Use -profile diann_v2_3_2")
    }
```

- [ ] **Step 4: Wire flags in insilico_library_generation**

In `modules/local/diann/insilico_library_generation/main.nf`:

a) Add `'--infin-dia'` and `'--pre-select'` to the blocked list.

b) Add flag variables:

```groovy
    infin_dia_flag = params.enable_infin_dia ? "--infin-dia" : ""
    pre_select_flag = params.diann_pre_select ? "--pre-select $params.diann_pre_select" : ""
```

c) Append both to the DIA-NN command.

- [ ] **Step 5: Validate and commit**

```bash
conda run -n nfcore pre-commit run --all-files
conda run -n nfcore nf-core pipelines lint --dir .
git add nextflow.config nextflow_schema.json workflows/dia.nf modules/local/diann/insilico_library_generation/main.nf
git commit -m "feat: add InfinDIA groundwork — enable_infin_dia param (#10)

Experimental support for InfinDIA (DIA-NN 2.3.0+). Passes --infin-dia
to library generation when enabled. Version guard enforces >= 2.3.0.
No test config — InfinDIA requires large databases."
```

---

## Task 10: Documentation — parameters.md

**Files:**
- Create: `docs/parameters.md`

- [ ] **Step 1: Create comprehensive parameter reference**

Create `docs/parameters.md` with all params from `nextflow_schema.json` grouped by category. Read `nextflow.config` and `nextflow_schema.json` to get every param, its type, default, and description. Group into:

1. Input/output options
2. File preparation
3. DIA-NN general
4. Mass accuracy and calibration
5. Library generation
6. Quantification and output
7. DDA mode
8. InfinDIA (experimental)
9. Quality control
10. MultiQC options
11. Boilerplate

Each param entry: `| name | type | default | description |`

- [ ] **Step 2: Commit**

```bash
git add docs/parameters.md
git commit -m "docs: add comprehensive parameter reference (#1)

Complete reference for all ~70 pipeline parameters grouped by category
with types, defaults, descriptions, and version requirements.

Closes #1"
```

---

## Task 11: Documentation — complete usage.md and output.md

**Files:**
- Modify: `docs/usage.md`
- Modify: `docs/output.md`
- Modify: `CITATIONS.md`
- Modify: `README.md`

- [ ] **Step 1: Add DDA section to usage.md**

Add a "DDA Analysis Mode" section after the Bruker/timsTOF section with:
- How to enable (`--diann_dda true -profile diann_v2_3_2`)
- Limitations (beta, trusted columns only, PTM unreliable, MBR limited)
- Example command
- Link to DIA-NN DDA documentation

- [ ] **Step 2: Add missing param sections to usage.md**

Add sections for:
- Preprocessing params (`reindex_mzml`, `mzml_statistics`, `convert_dotd`)
- QC params (`enable_pmultiqc`, `skip_table_plots`, `contaminant_string`)
- `diann_extra_args` scope per module
- `--verbose_modules` profile
- Container version override guide (DIA-NN version profiles)
- Singularity usage
- SLURM example

- [ ] **Step 3: Update output.md**

Add:
- Parquet vs TSV output explanation
- MSstats format section
- Intermediate outputs under `--verbose_modules`

- [ ] **Step 4: Add pmultiqc to CITATIONS.md**

Add pmultiqc citation after the MultiQC entry.

- [ ] **Step 5: Update README.md**

Add DIA-NN version support table and link to `docs/parameters.md`.

- [ ] **Step 6: Validate and commit**

```bash
conda run -n nfcore pre-commit run --all-files
git add docs/usage.md docs/output.md CITATIONS.md README.md
git commit -m "docs: complete usage.md, output.md, citations, README (#1, #3, #9, #15)

- DDA mode documentation with limitations
- Missing param sections (preprocessing, QC, extra_args scope)
- Container version override and Singularity guides
- Parquet vs TSV output explanation
- pmultiqc citation added
- README updated with version table

Closes #3, #9, #15"
```

---

## Task 12: Close resolved issues

- [ ] **Step 1: Close issues via GitHub CLI**

```bash
gh issue close 17 --repo bigbio/quantmsdiann --comment "Already implemented — --monitor-mod is extracted from diann_config.cfg (generated by sdrf-pipelines convert-diann) and passed to all DIA-NN steps via mod_flags."
gh issue close 2 --repo bigbio/quantmsdiann --comment "Superseded by #4 (Phase 6: consolidate param generation to sdrf-pipelines)."
gh issue close 1 --repo bigbio/quantmsdiann --comment "Resolved — docs/parameters.md created with comprehensive parameter reference."
gh issue close 3 --repo bigbio/quantmsdiann --comment "Resolved — diann_extra_args scope documented in docs/usage.md."
gh issue close 9 --repo bigbio/quantmsdiann --comment "Resolved — container version override guide and Singularity usage added to docs/usage.md."
gh issue close 15 --repo bigbio/quantmsdiann --comment "Resolved — docs/usage.md input documentation updated."
```

---

## Task 13: Final validation and push

- [ ] **Step 1: Run full validation suite**

```bash
conda run -n nfcore pre-commit run --all-files
conda run -n nfcore nf-core pipelines lint --release --dir .
```

Expected: 0 failures on both.

- [ ] **Step 2: Push dda branch and create PR**

```bash
git push -u origin dda
gh pr create --title "feat: v1.0.0 release — robustness, DDA support, features, docs" --body "$(cat <<'PREOF'
## Summary
- Robustness fixes: pipefail, error_retry, empty input guards
- DDA support via --diann_dda flag (DIA-NN >= 2.3.2)
- New params: --light-models, --export-quant, --site-ms1-quant
- InfinDIA groundwork (experimental)
- DIA-NN 2.3.2 version config
- New test configs: test_dda, test_dia_skip_preanalysis
- Comprehensive docs: parameters.md, complete usage.md, output.md

## Issues
Closes #1, #3, #5, #7, #9, #10, #15, #17

## Test plan
- [ ] Existing CI tests pass (test_dia, test_dia_dotd)
- [ ] New test_dda passes with BSA dataset on DIA-NN 2.3.2
- [ ] test_dia_skip_preanalysis passes
- [ ] nf-core lint --release: 0 failures
- [ ] pre-commit: all passing
PREOF
)" --base dev
```
