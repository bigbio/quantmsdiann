# bigbio/quantmsdiann: Usage

## Introduction

quantmsdiann is a Nextflow pipeline for DIA-NN-based quantitative mass spectrometry analysis.

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run bigbio/quantmsdiann \
    --input 'experiment.sdrf.tsv' \
    --database 'proteins.fasta' \
    --outdir './results' \
    -profile docker
```

The input file must be in [Sample-to-data-relationship format (SDRF)](https://pubs.acs.org/doi/abs/10.1021/acs.jproteome.0c00376) and can have `.sdrf`, `.tsv`, or `.csv` file extensions.

### Supported file formats

The pipeline supports the following mass spectrometry data file formats:

- **`.raw`** - Thermo RAW files (automatically converted to mzML)
- **`.mzML`** - Open standard mzML files
- **`.d`** - Bruker timsTOF files (processed natively by DIA-NN)
- **`.dia`** - DIA-NN native binary format (passed through without conversion)

Compressed variants are supported for `.raw`, `.mzML`, and `.d` formats: `.gz`, `.tar`, `.tar.gz`, `.zip`.

### Preprocessing Options

The pipeline includes several preprocessing steps that can be controlled via parameters:

- **`--reindex_mzml`** (default: `true`) -- Force re-indexing of input mzML files at the start of the pipeline. This fixes common issues with slightly incomplete or outdated mzML files and is enabled by default for safety. Set to `false` only if you are certain your mzML files are well-formed.

- **`--mzml_statistics`** (default: `false`) -- Compute MS1/MS2 statistics from mzML files. When enabled, `*_ms_info.parquet` files are generated for each mzML file and used in QC reporting. Bruker `.d` files are always skipped by this step.

- **`--mzml_features`** (default: `false`) -- Compute MS1-level features during the mzML statistics step. Only available for mzML files.

### Bruker/timsTOF Data

For Bruker timsTOF datasets, DIA-NN recommends manually fixing MS1 and MS2 mass accuracy (typically 10-15 ppm) rather than using automatic calibration. There are two ways to set this:

**Option 1 — SDRF columns (per-file control, recommended):**

Set `PrecursorMassTolerance`, `PrecursorMassToleranceUnit`, `FragmentMassTolerance`, and `FragmentMassToleranceUnit` columns in your SDRF file. The pipeline reads these per-file and passes them to DIA-NN when `--mass_acc_automatic false` is set. This allows different tolerances for different files in the same experiment.

**Option 2 — Pipeline parameters (global override):**

```bash
nextflow run bigbio/quantmsdiann \
  --input sdrf.tsv \
  --database proteins.fasta \
  --mass_acc_automatic false \
  --mass_acc_ms1 <value> \
  --mass_acc_ms2 <value> \
  -profile docker
```

For Synchro-PASEF data, enable `--diann_tims_sum` (which adds `--quant-tims-sum` to DIA-NN).

> [!NOTE]
> The pipeline will emit a warning during PRELIMINARY_ANALYSIS if it detects `.d` files with automatic mass accuracy calibration enabled, recommending to set tolerances via SDRF or pipeline parameters.

### Pipeline settings via params file

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`:

```bash
nextflow run bigbio/quantmsdiann -profile docker -params-file params.yaml
```

```yaml
input: "./experiment.sdrf.tsv"
database: "./proteins.fasta"
outdir: "./results"
```

> [!WARNING]
> Do not use `-c <file>` to specify parameters. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) or module arguments.

### Reproducibility

Specify the pipeline version when running on your data:

```bash
nextflow run bigbio/quantmsdiann -r 1.0.0 -profile docker --input sdrf.tsv --database db.fasta --outdir results
```

## Core Nextflow arguments

### `-profile`

Use this parameter to choose a configuration profile:

- `docker` - Run with Docker containers
- `singularity` - Run with Singularity containers
- `podman` - Run with Podman containers
- `apptainer` - Run with Apptainer containers

Multiple profiles can be loaded: `-profile test_dia,docker`

### `-resume`

Resume from cached results:

```bash
nextflow run bigbio/quantmsdiann -profile test_dia,docker --outdir results -resume
```

## Test profiles

```bash
# Quick DIA test
nextflow run . -profile test_dia,docker --outdir results

# DIA with Bruker .d files
nextflow run . -profile test_dia_dotd,docker --outdir results

# Latest DIA-NN version (2.1.0)
nextflow run . -profile test_latest_dia,docker --outdir results
```

## DIA-NN parameters

The pipeline passes parameters to DIA-NN at different steps. Some parameters come from the SDRF metadata (per-file), some from `nextflow.config` defaults, and some from the command line. The table below documents each parameter, its source, and which pipeline steps use it.

### Parameter sources

Parameters are resolved in this priority order:

1. **SDRF metadata** (per-file, from `convert-diann` design file) — highest priority
2. **Pipeline parameters** (`--param_name` on command line or params file)
3. **Nextflow defaults** (`nextflow.config`) — lowest priority

### Pipeline steps

| Step                            | Description                                                         |
| ------------------------------- | ------------------------------------------------------------------- |
| **INSILICO_LIBRARY_GENERATION** | Predicts a spectral library from FASTA using DIA-NN's deep learning |
| **PRELIMINARY_ANALYSIS**        | Per-file calibration and mass accuracy estimation (first pass)      |
| **ASSEMBLE_EMPIRICAL_LIBRARY**  | Builds consensus empirical library from preliminary results         |
| **INDIVIDUAL_ANALYSIS**         | Per-file quantification with the empirical library (second pass)    |
| **FINAL_QUANTIFICATION**        | Aggregates all files into protein/peptide matrices                  |

### Per-file parameters from SDRF

These parameters are extracted per-file from the SDRF via `convert-diann` and stored in `diann_design.tsv`:

| DIA-NN flag      | SDRF column                                        | Design column            | Steps                   | Notes                                           |
| ---------------- | -------------------------------------------------- | ------------------------ | ----------------------- | ----------------------------------------------- |
| `--mass-acc-ms1` | `comment[precursor mass tolerance]`                | `PrecursorMassTolerance` | PRELIMINARY, INDIVIDUAL | Falls back to auto-detect if missing or not ppm |
| `--mass-acc`     | `comment[fragment mass tolerance]`                 | `FragmentMassTolerance`  | PRELIMINARY, INDIVIDUAL | Falls back to auto-detect if missing or not ppm |
| `--min-pr-mz`    | `comment[ms1 scan range]` or `comment[ms min mz]`  | `MS1MinMz`               | PRELIMINARY, INDIVIDUAL | Per-file for GPF; global broadest for INSILICO  |
| `--max-pr-mz`    | `comment[ms1 scan range]` or `comment[ms max mz]`  | `MS1MaxMz`               | PRELIMINARY, INDIVIDUAL | Per-file for GPF; global broadest for INSILICO  |
| `--min-fr-mz`    | `comment[ms2 scan range]` or `comment[ms2 min mz]` | `MS2MinMz`               | PRELIMINARY, INDIVIDUAL | Per-file for GPF; global broadest for INSILICO  |
| `--max-fr-mz`    | `comment[ms2 scan range]` or `comment[ms2 max mz]` | `MS2MaxMz`               | PRELIMINARY, INDIVIDUAL | Per-file for GPF; global broadest for INSILICO  |

### Global parameters from config

These parameters apply globally across all files. They are set in `diann_config.cfg` (from SDRF) or as pipeline parameters:

| DIA-NN flag                                   | Pipeline parameter                                 | Default                                         | Steps                                    | Notes                                                           |
| --------------------------------------------- | -------------------------------------------------- | ----------------------------------------------- | ---------------------------------------- | --------------------------------------------------------------- |
| `--cut`                                       | (from SDRF enzyme)                                 | —                                               | ALL                                      | Enzyme cut rule, derived from `comment[cleavage agent details]` |
| `--fixed-mod`                                 | (from SDRF)                                        | —                                               | ALL                                      | Fixed modifications from `comment[modification parameters]`     |
| `--var-mod`                                   | (from SDRF)                                        | —                                               | ALL                                      | Variable modifications from `comment[modification parameters]`  |
| `--monitor-mod`                               | `--enable_mod_localization` + `--mod_localization` | `false` / `Phospho (S),Phospho (T),Phospho (Y)` | PRELIMINARY, ASSEMBLE, INDIVIDUAL, FINAL | PTM site localization scoring (DIA-NN 1.8.x only)               |
| `--window`                                    | `--scan_window`                                    | `8`                                             | PRELIMINARY, ASSEMBLE, INDIVIDUAL        | Scan window; auto-detected when `--scan_window_automatic=true`  |
| `--quick-mass-acc`                            | `--quick_mass_acc`                                 | `true`                                          | PRELIMINARY                              | Fast mass accuracy calibration                                  |
| `--min-corr 2 --corr-diff 1 --time-corr-only` | `--performance_mode`                               | `true`                                          | PRELIMINARY                              | High-speed, low-RAM mode                                        |
| `--pg-level`                                  | `--pg_level`                                       | `2`                                             | INDIVIDUAL, FINAL                        | Protein grouping level                                          |
| `--species-genes`                             | `--species_genes`                                  | `false`                                         | FINAL                                    | Use species-specific gene names                                 |
| `--no-norm`                                   | `--diann_normalize`                                | `true`                                          | FINAL                                    | Disable normalization when `false`                              |

### PTM site localization (`--monitor-mod`)

DIA-NN supports PTM site localization scoring via `--monitor-mod`. When enabled, DIA-NN reports `PTM.Site.Confidence` and `PTM.Q.Value` columns for the specified modifications.

**Important**: `--monitor-mod` is applied to all DIA-NN steps **except INSILICO_LIBRARY_GENERATION** (where it has no effect). It is particularly important for:

- **PRELIMINARY_ANALYSIS**: Affects PTM-aware scoring during calibration.
- **ASSEMBLE_EMPIRICAL_LIBRARY**: Strongly affects empirical library generation for PTM peptides.
- **INDIVIDUAL_ANALYSIS** and **FINAL_QUANTIFICATION**: Enables PTM site confidence scoring.

Note: For DIA-NN 2.0+, `--monitor-mod` is no longer needed — PTM localization is handled automatically by `--var-mod`. The flag is only used for DIA-NN 1.8.x.

To enable PTM site localization:

```bash
nextflow run bigbio/quantmsdiann \
    --enable_mod_localization \
    --mod_localization 'Phospho (S),Phospho (T),Phospho (Y)' \
    ...
```

The parameter accepts two formats:

- **Modification names** (quantms-compatible): `Phospho (S),Phospho (T),Phospho (Y)` — site info in parentheses is stripped, the base name is mapped to UniMod
- **UniMod accessions** (direct): `UniMod:21,UniMod:1`

Supported modification name mappings:

| Name        | UniMod ID    | Example                               |
| ----------- | ------------ | ------------------------------------- |
| Phospho     | `UniMod:21`  | `Phospho (S),Phospho (T),Phospho (Y)` |
| GlyGly      | `UniMod:121` | `GlyGly (K)`                          |
| Acetyl      | `UniMod:1`   | `Acetyl (Protein N-term)`             |
| Oxidation   | `UniMod:35`  | `Oxidation (M)`                       |
| Deamidated  | `UniMod:7`   | `Deamidated (N),Deamidated (Q)`       |
| Methylation | `UniMod:34`  | `Methylation (K),Methylation (R)`     |

## Passing Extra Arguments to DIA-NN

The `--diann_extra_args` parameter appends additional DIA-NN command-line flags to **all** DIA-NN steps (INSILICO_LIBRARY_GENERATION, PRELIMINARY_ANALYSIS, ASSEMBLE_EMPIRICAL_LIBRARY, INDIVIDUAL_ANALYSIS, FINAL_QUANTIFICATION).

```bash
nextflow run bigbio/quantmsdiann \
    --diann_extra_args '--smart-profiling --peak-center' \
    ...
```

Flags that conflict with a specific step are **automatically stripped** with a warning. Each module maintains its own block list of managed flags. The table below summarises the key blocked flags per step:

| Step                        | Key blocked flags (managed by pipeline)                                                                                                                                                                                                                                          |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| INSILICO_LIBRARY_GENERATION | `--fasta`, `--fasta-search`, `--gen-spec-lib`, `--predictor`, `--lib`, `--missed-cleavages`, `--min-pep-len`, `--max-pep-len`, `--min-pr-charge`, `--max-pr-charge`, `--var-mods`, `--min-pr-mz`, `--max-pr-mz`, `--min-fr-mz`, `--max-fr-mz`, `--met-excision`, `--monitor-mod` |
| PRELIMINARY_ANALYSIS        | `--mass-acc`, `--mass-acc-ms1`, `--window`, `--quick-mass-acc`, `--min-corr`, `--corr-diff`, `--time-corr-only`, `--min-pr-mz`, `--max-pr-mz`, `--min-fr-mz`, `--max-fr-mz`, `--monitor-mod`, `--var-mod`, `--fixed-mod`                                                         |
| ASSEMBLE_EMPIRICAL_LIBRARY  | `--mass-acc`, `--mass-acc-ms1`, `--window`, `--individual-mass-acc`, `--individual-windows`, `--out-lib`, `--gen-spec-lib`, `--rt-profiling`, `--monitor-mod`, `--var-mod`, `--fixed-mod`                                                                                        |
| INDIVIDUAL_ANALYSIS         | `--mass-acc`, `--mass-acc-ms1`, `--window`, `--pg-level`, `--relaxed-prot-inf`, `--no-ifs-removal`, `--min-pr-mz`, `--max-pr-mz`, `--min-fr-mz`, `--max-fr-mz`, `--monitor-mod`, `--var-mod`, `--fixed-mod`                                                                      |
| FINAL_QUANTIFICATION        | `--pg-level`, `--species-genes`, `--no-norm`, `--report-decoys`, `--xic`, `--qvalue`, `--window`, `--individual-windows`, `--monitor-mod`, `--var-mod`, `--fixed-mod`                                                                                                            |

All steps also block shared infrastructure flags: `--out`, `--temp`, `--threads`, `--verbose`, `--lib`, `--f`, `--fasta`, `--use-quant`, `--matrices`, `--no-main-report`.

For step-specific overrides that bypass this mechanism, use custom Nextflow config files with `ext.args`:

```groovy
// custom.config -- add a flag only to FINAL_QUANTIFICATION
process {
    withName: '.*:FINAL_QUANTIFICATION' {
        ext.args = '--my-special-flag'
    }
}
```

## DIA-NN Version Selection

The pipeline supports multiple DIA-NN versions via built-in Nextflow profiles. Each profile sets `params.diann_version` and overrides the container image for all `diann`-labelled processes.

| Profile        | DIA-NN Version | Container                                  | Key features                                                   |
| -------------- | -------------- | ------------------------------------------ | -------------------------------------------------------------- |
| `diann_v1_8_1` | 1.8.1          | `docker.io/biocontainers/diann:v1.8.1_cv1` | Default. Public BioContainers image. TSV output.               |
| `diann_v2_1_0` | 2.1.0          | `ghcr.io/bigbio/diann:2.1.0`               | Parquet output. Native .raw on Linux. QuantUMS (`--quantums`). |
| `diann_v2_2_0` | 2.2.0          | `ghcr.io/bigbio/diann:2.2.0`               | Speed optimizations (up to 1.6x on HPC). Parquet output.       |
| `diann_v2_3_2` | 2.3.2          | `ghcr.io/bigbio/diann:2.3.2`               | DDA support (`--diann_dda`), InfinDIA, up to 9 variable mods.  |

**Version-dependent features:** Some parameters are only available with newer DIA-NN versions. The pipeline handles version compatibility automatically:

- **QuantUMS** (`--quantums`): Requires >= 1.9.2. The `--direct-quant` flag is automatically skipped for DIA-NN 1.8.x where direct quantification is the only mode.
- **DDA mode** (`--diann_dda`): Requires >= 2.3.2. The pipeline will error if enabled with an older version.
- **InfinDIA** (`--enable_infin_dia`): Requires >= 2.3.0.

Usage:

```bash
# Run with DIA-NN 2.2.0
nextflow run bigbio/quantmsdiann \
    -profile diann_v2_2_0,docker \
    --input sdrf.tsv --database db.fasta --outdir results

# Run with DIA-NN 2.3.2 (latest, enables DDA and InfinDIA)
nextflow run bigbio/quantmsdiann \
    -profile diann_v2_3_2,docker \
    --input sdrf.tsv --database db.fasta --outdir results
```

> [!NOTE]
> DIA-NN 2.x images are hosted on `ghcr.io/bigbio` and may require authentication for private registries. The `diann_v2_1_0` and `diann_v2_2_0` profiles force Docker mode by default; for Singularity, override with your own config.

## Verbose Module Output

By default, only final result files are published. For debugging or detailed inspection, the `verbose_modules` profile publishes all intermediate files from every DIA-NN step:

```bash
nextflow run bigbio/quantmsdiann -profile verbose_modules,docker ...
```

This publishes intermediate outputs to descriptive subdirectories (e.g. `spectra/thermorawfileparser/`, `diann_preprocessing/preliminary_analysis/`, `library_generation/`). See [Output: Verbose Output Structure](output.md#verbose-output-structure) for the full directory layout.

## Container Version Override Guide

You can override the container image for any process without modifying pipeline code. This is useful for testing custom or newer DIA-NN builds.

**Docker:**

```groovy
// custom_container.config
process {
    withLabel: diann {
        container = 'my-registry.io/diann:custom-build'
    }
}
```

```bash
nextflow run bigbio/quantmsdiann -c custom_container.config -profile docker ...
```

**Singularity with caching:**

```groovy
// custom_singularity.config
singularity.cacheDir = '/path/to/singularity/cache'

process {
    withLabel: diann {
        container = '/path/to/diann_custom.sif'
    }
}
```

```bash
nextflow run bigbio/quantmsdiann -c custom_singularity.config -profile singularity ...
```

## SLURM Example

For running on HPC clusters with SLURM, the pipeline includes a reference configuration at `conf/pride_codon_slurm.config`. Use it via the `pride_slurm` profile:

```bash
nextflow run bigbio/quantmsdiann \
    -profile pride_slurm \
    --input sdrf.tsv --database db.fasta --outdir results
```

This profile enables Singularity, sets SLURM as the executor, and provides resource scaling for large experiments. Adapt it as a template for your own cluster by creating a custom config file.

## Optional outputs

By default, only final result files are published. Intermediate files can be exported using `save_*` parameters or via `ext.*` properties in a custom Nextflow config.

| Parameter            | Default | Description                                                                                 |
| -------------------- | ------- | ------------------------------------------------------------------------------------------- |
| `--save_speclib_tsv` | `false` | Publish the TSV spectral library from in-silico library generation to `library_generation/` |

**Using a parameter:**

```bash
nextflow run bigbio/quantmsdiann \
    --input 'experiment.sdrf.tsv' \
    --database 'proteins.fasta' \
    --save_speclib_tsv \
    --outdir './results' \
    -profile docker
```

**Using a custom Nextflow config (ext properties):**

```groovy
// custom.config
process {
    withName: '.*:INSILICO_LIBRARY_GENERATION' {
        ext.publish_speclib_tsv = true
    }
}
```

```bash
nextflow run bigbio/quantmsdiann -c custom.config ...
```

For full verbose output of all intermediate files (useful for debugging), use the `verbose_modules` profile:

```bash
nextflow run bigbio/quantmsdiann -profile verbose_modules,docker ...
```

## Custom configuration

### Resource requests

Each step in the pipeline has default resource requirements. If a job exits with error code `137` or `143` (exceeded resources), it will automatically resubmit with higher requests (2x, then 3x original).

To customize resources for a specific process:

```nextflow
process {
    withName: 'BIGBIO_QUANTMSDIANN:QUANTMSDIANN:DIA:FINAL_QUANTIFICATION' {
        memory = 100.GB
    }
}
```

Save this to a file and pass via `-c custom.config`.

## Running in the background

Use `screen`, `tmux`, or the Nextflow `-bg` flag to run the pipeline in the background:

```bash
nextflow run bigbio/quantmsdiann -profile docker --input sdrf.tsv --database db.fasta --outdir results -bg
```

## Developer testing with local containers

When developing changes to `sdrf-pipelines` or `quantms-utils`, you can build local Docker containers and test them with the pipeline without publishing to a registry.

### 1. Build local dev containers

```bash
# From sdrf-pipelines repo
cd /path/to/sdrf-pipelines
docker build -f Dockerfile.dev -t local/sdrf-pipelines:dev .

# From quantms-utils repo
cd /path/to/quantms-utils
docker build -f Dockerfile.dev -t local/quantms-utils:dev .
```

### 2. Run the pipeline with local containers

Use the `test_dia_local.config` to override container references:

```bash
nextflow run main.nf \
    -profile test_dia,docker \
    -c conf/tests/test_dia_local.config \
    --outdir results
```

This config (`conf/tests/test_dia_local.config`) overrides:

- `SDRF_PARSING` → `local/sdrf-pipelines:dev`
- `SAMPLESHEET_CHECK` → `local/quantms-utils:dev`
- `DIANN_MSSTATS` → `local/quantms-utils:dev`

### 3. Using pre-converted mzML files

To skip ThermoRawFileParser (useful on macOS/ARM where Mono crashes):

```bash
# Convert raw files with ThermoRawFileParser v2.0+
docker run --rm --platform=linux/amd64 \
    -v /path/to/raw:/data -v /path/to/mzml:/out \
    quay.io/biocontainers/thermorawfileparser:2.0.0.dev--h9ee0642_0 \
    ThermoRawFileParser -d /data -o /out -f 2

# Run pipeline with pre-converted files
nextflow run main.nf \
    -profile test_dia,docker \
    -c conf/tests/test_dia_local.config \
    --root_folder /path/to/mzml \
    --local_input_type mzML \
    --outdir results
```

## Nextflow memory requirements

Add the following to your environment to limit Java memory:

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
