# bigbio/quantmsdiann: Usage

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

<!-- TODO nf-core: Add documentation about anything specific to running your pipeline. For general topics, please point to (and add to) the main nf-core website. -->

## Samplesheet input

You will need to create a samplesheet with information about the samples you would like to analyse before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 3 columns, and a header row as shown in the examples below.

```bash
--input '[path to samplesheet file]'
```

### Multiple runs of the same sample

The `sample` identifiers have to be the same when you have re-sequenced the same sample more than once e.g. to increase sequencing depth. The pipeline will concatenate the raw reads before performing any downstream analysis. Below is an example for the same sample sequenced across 3 lanes:

```csv title="samplesheet.csv"
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
CONTROL_REP1,AEG588A1_S1_L003_R1_001.fastq.gz,AEG588A1_S1_L003_R2_001.fastq.gz
CONTROL_REP1,AEG588A1_S1_L004_R1_001.fastq.gz,AEG588A1_S1_L004_R2_001.fastq.gz
```

### Full samplesheet

The pipeline will auto-detect whether a sample is single- or paired-end using the information provided in the samplesheet. The samplesheet can have as many columns as you desire, however, there is a strict requirement for the first 3 columns to match those defined in the table below.

A final samplesheet file consisting of both single- and paired-end data may look something like the one below. This is for 6 samples, where `TREATMENT_REP3` has been sequenced twice.

```csv title="samplesheet.csv"
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
CONTROL_REP2,AEG588A2_S2_L002_R1_001.fastq.gz,AEG588A2_S2_L002_R2_001.fastq.gz
CONTROL_REP3,AEG588A3_S3_L002_R1_001.fastq.gz,AEG588A3_S3_L002_R2_001.fastq.gz
TREATMENT_REP1,AEG588A4_S4_L003_R1_001.fastq.gz,
TREATMENT_REP2,AEG588A5_S5_L003_R1_001.fastq.gz,
TREATMENT_REP3,AEG588A6_S6_L003_R1_001.fastq.gz,
TREATMENT_REP3,AEG588A6_S6_L004_R1_001.fastq.gz,
```

| Column    | Description                                                                                                                                                                            |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`  | Custom sample name. This entry will be identical for multiple sequencing libraries/runs from the same sample. Spaces in sample names are automatically converted to underscores (`_`). |
| `fastq_1` | Full path to FastQ file for Illumina short reads 1. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                             |
| `fastq_2` | Full path to FastQ file for Illumina short reads 2. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                             |

An [example samplesheet](../assets/samplesheet.csv) has been provided with the pipeline.

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run bigbio/quantmsdiann --input ./samplesheet.csv --outdir ./results --genome GRCh37 -profile docker
```

<<<<<<< HEAD
The input file must be in [Sample-to-data-relationship format (SDRF)](https://pubs.acs.org/doi/abs/10.1021/acs.jproteome.0c00376) and can have `.sdrf`, `.tsv`, or `.csv` file extensions.
=======
This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.
>>>>>>> fe9e018 (Template update for nf-core/tools version 4.0.2)

Note that the pipeline will create the following files in your working directory:

```bash
<<<<<<< HEAD
nextflow run bigbio/quantmsdiann \
  --input sdrf.tsv \
  --database proteins.fasta \
  --mass_acc_automatic false \
  --mass_acc_ms1 <value> \
  --mass_acc_ms2 <value> \
  -profile docker
=======
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
>>>>>>> fe9e018 (Template update for nf-core/tools version 4.0.2)
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> [!WARNING]
> Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/running/run-pipelines#configuring-pipelines), other infrastructural tweaks (such as output directories), or module arguments (args).

<<<<<<< HEAD
DIA-NN 2.3.2+ supports DDA data analysis via the `--dda` flag. The pipeline **auto-detects DDA mode** from the SDRF `comment[proteomics data acquisition method]` column — no extra flags needed if your SDRF contains `data-dependent acquisition`:

```bash
nextflow run bigbio/quantmsdiann \
  --input dda_sdrf.tsv \
  --database proteins.fasta \
  -profile diann_v2_3_2,docker
```

If your SDRF does not include the acquisition method column, you can explicitly enable DDA mode with `--dda true`:

```bash
nextflow run bigbio/quantmsdiann \
  --input sdrf.tsv \
  --database proteins.fasta \
  --dda true \
  -profile diann_v2_3_2,docker
```

**Limitations (beta feature):**

- Only trust: q-values, PEP values, RT/IM values, Ms1.Apex.Area, Normalisation.Factor
- PTM localization probabilities are **unreliable** with DDA data
- MBR requires MS2-level evidence (DIA-like, not classical DDA MBR)
- No isobaric labeling or reporter-tag quantification
- Primary use cases: legacy DDA reanalysis, spectral library creation, immunopeptidomics

The pipeline uses the same workflow for DDA as DIA — the `--dda` flag is passed to all DIA-NN steps automatically when DDA is detected from the SDRF or enabled via `--dda`.

### Preprocessing Options

- `--reindex_mzml` (default: true) — Re-index mzML files before processing. Disable with `--reindex_mzml false` if files are already indexed.
- `--mzml_statistics` (default: false) — Generate mzML statistics (parquet format) for QC.
- `--mzml_features` (default: false) — Enable feature detection in mzML statistics.

Bruker `.d` files are supported natively by the current workflow and are passed directly to DIA-NN; there is no `--convert_dotd` preprocessing option.

### Passing Extra Arguments to DIA-NN

Use `--extra_args` to pass additional flags to all DIA-NN steps. The pipeline validates and strips flags it manages internally to prevent conflicts.

Managed flags (stripped with a warning if passed via extra_args): `--lib`, `--f`, `--fasta`, `--threads`, `--verbose`, `--temp`, `--out`, `--matrices`, `--use-quant`, `--gen-spec-lib`, `--mass-acc`, `--mass-acc-ms1`, `--window`, `--var-mod`, `--fixed-mod`, `--monitor-mod`, and others.

To enable this, add `includeConfig 'conf/modules/dia.config'` to your configuration (already included by default).

### DIA-NN Version Selection

The default DIA-NN version is 1.8.1. To use a different version:

| Version | Profile                 | Features                            |
| ------- | ----------------------- | ----------------------------------- |
| 1.8.1   | (default)               | Core DIA analysis                   |
| 2.1.0   | `-profile diann_v2_1_0` | Native .raw support, reduced memory |
| 2.2.0   | `-profile diann_v2_2_0` | Speed optimizations                 |
| 2.3.2   | `-profile diann_v2_3_2` | DDA support, InfinDIA               |
| 2.5.0   | `-profile diann_v2_5_0` | +70% protein IDs, model fine-tuning |

Example: `nextflow run bigbio/quantmsdiann -profile test_dia,docker,diann_v2_2_0`

### Verbose Module Output

Use `-profile verbose_modules` to publish intermediate files from all pipeline steps:

```bash
nextflow run bigbio/quantmsdiann -profile test_dia,docker,verbose_modules --outdir results
```

This publishes ThermoRawFileParser conversions, mzML indexing results, per-file DIA-NN logs, and spectral library intermediates.

### Pipeline settings via params file

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`:
=======
The above pipeline run specified with a params file in yaml format:
>>>>>>> fe9e018 (Template update for nf-core/tools version 4.0.2)

```bash
nextflow run bigbio/quantmsdiann -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
input: './samplesheet.csv'
outdir: './results/'
genome: 'GRCh37'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull bigbio/quantmsdiann
```

### Reproducibility

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

<<<<<<< HEAD
```bash
nextflow run bigbio/quantmsdiann -r 2.0.0 -profile docker --input sdrf.tsv --database db.fasta --outdir results
```
=======
First, go to the [bigbio/quantmsdiann releases page](https://github.com/bigbio/quantmsdiann/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducibility, you can use share and reuse [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> [!TIP]
> If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.
>>>>>>> fe9e018 (Template update for nf-core/tools version 4.0.2)

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

> [!IMPORTANT]
> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to check if your system is supported, please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://charliecloud.io/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

<<<<<<< HEAD
```bash
# Quick DIA test
nextflow run . -profile test_dia,docker --outdir results

# DIA with Bruker .d files
nextflow run . -profile test_dia_dotd,docker --outdir results

# Latest DIA-NN version (2.5.0)
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
| `--no-norm`                                   | `--normalize`                                      | `true`                                          | FINAL                                    | Disable normalization when `false`                              |

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

The `--extra_args` parameter appends additional DIA-NN command-line flags to **all** DIA-NN steps (INSILICO_LIBRARY_GENERATION, PRELIMINARY_ANALYSIS, ASSEMBLE_EMPIRICAL_LIBRARY, INDIVIDUAL_ANALYSIS, FINAL_QUANTIFICATION).

```bash
nextflow run bigbio/quantmsdiann \
    --extra_args '--smart-profiling --peak-center' \
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

| Profile        | DIA-NN Version | Container                                  | Key features                                                    |
| -------------- | -------------- | ------------------------------------------ | --------------------------------------------------------------- |
| `diann_v1_8_1` | 1.8.1          | `docker.io/biocontainers/diann:v1.8.1_cv1` | Default. Public BioContainers image. TSV output.                |
| `diann_v2_1_0` | 2.1.0          | `ghcr.io/bigbio/diann:2.1.0`               | Parquet output. Native .raw on Linux. QuantUMS (`--quantums`).  |
| `diann_v2_2_0` | 2.2.0          | `ghcr.io/bigbio/diann:2.2.0`               | Speed optimizations (up to 1.6x on HPC). Parquet output.        |
| `diann_v2_3_2` | 2.3.2          | `ghcr.io/bigbio/diann:2.3.2`               | DDA support (`--dda`), InfinDIA, up to 9 variable mods.         |
| `diann_v2_5_0` | 2.5.0          | `ghcr.io/bigbio/diann:2.5.0`               | Up to 70% more protein IDs. DL model fine-tuning and selection. |

**Version-dependent features:** Some parameters are only available with newer DIA-NN versions. The pipeline handles version compatibility automatically:

- **QuantUMS** (`--quantums`): Requires >= 1.9.2. The `--direct-quant` flag is automatically skipped for DIA-NN 1.8.x where direct quantification is the only mode.
- **DDA mode** (`--dda`): Requires >= 2.3.2. The pipeline will error if enabled with an older version.
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
> DIA-NN 1.8.1 uses a public BioContainers image (no auth). DIA-NN 2.x images are on `ghcr.io/bigbio` and require GHCR authentication. You can also build containers yourself from [quantms-containers](https://github.com/bigbio/quantms-containers).

### Using custom containers on HPC

For HPC/Singularity deployments with local `.sif` files, create a config that overrides the container:

```groovy
// hpc_diann.config
process {
    withLabel: diann {
        container = '/path/to/sif/diann-2.5.0.sif'
    }
}
```

```bash
nextflow run bigbio/quantmsdiann \
    -profile singularity -c hpc_diann.config \
    --diann_version '2.5.0' \
    --input sdrf.tsv --database db.fasta --outdir results
```

> [!IMPORTANT]
> Set `--diann_version` to match your container. Do **not** combine with `-profile diann_v2_5_0` (it would override your local path).

For the full guide on building containers, GHCR authentication, version switching, and SLURM deployment, see the [Containers documentation](https://quantmsdiann.quantms.org/containers/).

## Fine-Tuning Deep Learning Models (DIA-NN 2.0+)

DIA-NN uses deep learning models to predict retention time (RT), ion mobility (IM), and fragment ion intensities. For non-standard modifications, fine-tuning these models on real data can substantially improve detection.

**When to fine-tune:** Fine-tuning is beneficial for custom chemical labels (e.g., mTRAQ, dimethyl), exotic PTMs, or unmodified cysteines. Standard modifications (Phospho, Oxidation, Acetylation, Deamidation, diGlycine) do not require fine-tuning — DIA-NN's built-in models already handle them well.

### How fine-tuning works

DIA-NN's neural networks encode each amino acid and modification as a "token" — an integer ID (0-255) mapped in a dictionary file (`dict.txt`). The default dictionary ships with DIA-NN and covers common modifications. When you fine-tune, DIA-NN:

1. Reads a spectral library containing empirically observed peptides with the modifications of interest
2. Learns how those modifications affect RT, IM, and fragmentation patterns
3. Outputs new model files (`.pt` PyTorch format) and an expanded dictionary (`dict.txt`) that includes tokens for the new modifications

The fine-tuned models are then used in place of the defaults when generating predicted spectral libraries.

> [!NOTE]
> **`--tune-lib` cannot be combined with `--gen-spec-lib` in a single DIA-NN invocation** ([confirmed in DIA-NN #1499](https://github.com/vdemichev/DiaNN/issues/1499)). Fine-tuning and library generation are still separate DIA-NN commands, but quantmsdiann can now orchestrate them within a single pipeline run when `--enable_fine_tuning` is used. Integrated fine-tuning requires DIA-NN v2.5.0 or later. The two-run/manual approach below is only needed when integrated fine-tuning is not enabled, or when using an older DIA-NN version that does not support this workflow.

### Manual fallback workflow (two-run fine-tuning)

**Run 1 — Generate the tuning library:**

Run quantmsdiann normally. The empirical library produced by the ASSEMBLE_EMPIRICAL_LIBRARY step (after preliminary analysis) serves as the tuning library. This library contains empirically observed RT, IM, and fragment intensities for peptides bearing the modifications of interest.

```bash
# First run: standard pipeline to produce empirical library
nextflow run bigbio/quantmsdiann \
    -profile diann_v2_5_0,docker \
    --input sdrf.tsv --database db.fasta --outdir results_run1
# Output: results_run1/library_generation/assemble_empirical_library/empirical_library.parquet
```

**Fine-tune models (outside the pipeline):**

```bash
# Fine-tune RT and IM models using the empirical library
diann --tune-lib /abs/path/to/empirical_library.parquet --tune-rt --tune-im

# Optionally also fine-tune the fragmentation model (quality-sensitive — verify vs base model)
diann --tune-lib /abs/path/to/empirical_library.parquet --tune-rt --tune-im --tune-fr
```

DIA-NN will output (named after the input library):

- `empirical_library.dict.txt` — expanded tokenizer dictionary with new modification tokens
- `empirical_library.rt.d0.pt` (+ `.d1.pt`, `.d2.pt`) — fine-tuned RT models (3 distillation levels)
- `empirical_library.im.d0.pt` (+ `.d1.pt`, `.d2.pt`) — fine-tuned IM models
- `empirical_library.fr.d0.pt` (+ `.d1.pt`, `.d2.pt`) — fine-tuned fragment models (if `--tune-fr`)

Additional tuning parameters: `--tune-lr` (learning rate, default 0.0005), `--tune-restrict-layers` (fix RNN weights), `--tune-level` (limit to a specific distillation level 0/1/2).

**Run 2 — Re-run the pipeline with fine-tuned models:**

```bash
# Second run: use tuned models for in-silico library generation and all downstream steps
nextflow run bigbio/quantmsdiann \
    -profile diann_v2_5_0,docker \
    --input sdrf.tsv --database db.fasta \
    --extra_args "--tokens /abs/path/to/empirical_library.dict.txt --rt-model /abs/path/to/empirical_library.rt.d0.pt --im-model /abs/path/to/empirical_library.im.d0.pt" \
    --outdir results_run2
```

The `--tokens`, `--rt-model`, and `--im-model` flags are passed to all DIA-NN steps via `--extra_args`, so the in-silico library generation uses the fine-tuned models to produce better-predicted spectra for the non-standard modifications.

> [!IMPORTANT]
> Use **absolute paths** for model files. The `--parent` flag is blocked by the pipeline (it controls the container's DIA-NN installation path).

### Integrated fine-tuning step

The pipeline now includes an optional integrated fine-tuning phase, which eliminates the need for two separate runs. You can enable this feature by using the `--enable_fine_tuning` flag. The integrated workflow is:

```
INSILICO_LIBRARY → PRELIMINARY_ANALYSIS → ASSEMBLE_EMPIRICAL_LIBRARY
    → [FINE_TUNE_MODELS] → INSILICO_LIBRARY (with tuned models)
    → INDIVIDUAL_ANALYSIS → FINAL_QUANTIFICATION
```

This would be gated by a `--enable_fine_tuning` parameter. [@vdemichev](https://github.com/vdemichev): would this approach work correctly — using the empirical library from assembly as `--tune-lib`, then regenerating the in-silico library with the tuned models before proceeding to individual analysis? Or would you recommend a different integration point?

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
=======
Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.
>>>>>>> fe9e018 (Template update for nf-core/tools version 4.0.2)

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the pipeline steps, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher resources request (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#set-max-resources) and [customise process resources](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#customize-process-resources) section of the nf-core website.

### Custom Containers

In some cases, you may wish to change the container or conda environment used by a pipeline steps for a particular tool. By default, nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However, in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#update-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/running/configuration/nextflow-for-your-system#modifying-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

<<<<<<< HEAD
```bash
nextflow run bigbio/quantmsdiann -profile docker --input sdrf.tsv --database db.fasta --outdir results -bg
```
=======
The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.
>>>>>>> fe9e018 (Template update for nf-core/tools version 4.0.2)

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
