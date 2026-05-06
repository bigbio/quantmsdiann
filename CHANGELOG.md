# bigbio/quantmsdiann: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] bigbio/quantmsdiann — Sao Pablo - 2026-05-05

### `Added`

- Optional PRIDE Archive download via [pridepy](https://github.com/PRIDE-Archive/pridepy) (`--pridepy_download`). Downloads raw files before analysis using Globus, FTP, or Aspera. Controlled by `--pridepy_protocol` and `--aspera_maximum_bandwidth`.
- `--mzml_convert` parameter to control Thermo `.raw` conversion. Default (unset) auto-selects based on `--diann_version`: converts via ThermoRawFileParser for DIA-NN < 2.1.0, passes `.raw` natively to DIA-NN for >= 2.1.0. Explicit `true` forces conversion (useful for `--mzml_statistics` or to work around DIA-NN Thermo reader issues like [DiaNN#1468](https://github.com/vdemichev/DiaNN/issues/1468)); explicit `false` requires DIA-NN >= 2.1.0 and skips TRFP entirely (closes [#66](https://github.com/bigbio/quantmsdiann/issues/66)).
- Schema-level enum validation for `--local_input_type`, with a matching runtime guard in `CREATE_INPUT_CHANNEL` that fails fast and lists the supported values when an unknown type is supplied under `--root_folder`.
- Bruker `.d` archive variants `d.tar`, `d.tar.gz`, and `d.zip` as accepted `--local_input_type` values; archives are decompressed automatically by the workflow.

### `Changed`

- Default for `--local_input_type` switched from `mzML` to `raw` to match the typical local-input flow (SDRF-referenced `.raw` files staged via `--root_folder`). **Migration:** users who point `--root_folder` at a local mzML cache must now pass `--local_input_type mzML` explicitly.
- Default for `--reindex_mzml` switched from `true` to `false`. ThermoRawFileParser and the wiff converter both emit indexed mzML, and DIA-NN handles unindexed mzML on its own, so the OpenMS `FileConverter` step is redundant in the common flow. **Migration:** users who feed pre-built mzML files that may be unindexed should pass `--reindex_mzml true` explicitly.
- `ASSEMBLE_EMPIRICAL_LIBRARY` resource scaling in `conf/pride_codon_slurm.config` simplified: the manual `Math.min` clamps were removed because `resourceLimits` already caps memory and cpus.
- `--input` is now restricted to files with the `.sdrf.tsv` extension (schema pattern `^\S+\.sdrf\.tsv$`). Inputs ending in `.sdrf`, `.tsv`, or `.csv` are rejected at startup by nf-schema validation. **Migration:** rename existing samplesheets (e.g. `experiment.tsv` → `experiment.sdrf.tsv`); users with `.csv` inputs must convert to TSV beforehand. The `SAMPLESHEET_CHECK` module no longer carries the in-process pandas-based CSV→TSV conversion or `.sdrf → .sdrf.tsv` renaming, since the file extension is now guaranteed by the schema.

### `Fixed`

- DIA-NN per-file processes (`PRELIMINARY_ANALYSIS`, `INDIVIDUAL_ANALYSIS`, `ASSEMBLE_EMPIRICAL_LIBRARY`) now use `stageInMode 'copy'` when native `.raw` mode is active. DIA-NN's native Thermo reader fails when `.raw` files are staged as symlinks (Thermo SDK limitation); the copy-mode closure only kicks in for DIA-NN >= 2.1.0 with `--mzml_convert != true`.

## [2.0.0] bigbio/quantmsdiann — Rome - 2026-04-18

### `Added`

- DDA analysis mode support (requires DIA-NN >= 2.3.2), auto-detected from SDRF or set via `--dda`
- DIA-NN 2.3.2 and 2.5.0 version profiles (`-profile diann_v2_3_2`, `-profile diann_v2_5_0`)
- DIA-NN 2.5.0 support: up to 70% more protein IDs, deep learning model fine-tuning and selection
- Optional integrated fine-tuning step (`--enable_fine_tuning`): trains RT/IM/fragment models on a file subset before the main analysis, then regenerates the in-silico library with tuned models — no need for two separate pipeline runs
- Fine-tuning parameters: `--tune_n_files`, `--tune_fr`, `--tune_lr`
- Support for user-provided fine-tuned models via `--extra_args` (`--tokens`, `--rt-model`, `--fr-model`, `--im-model`)
- Scoring mode parameter (`--scoring_mode`): `generic` (default), `proteoforms` (proteogenomics/variant detection, >= 2.0), `peptidoforms` (PTM analysis)
- Amino acid equivalence parameter (`--aa_eq`) for entrapment FDR benchmarks (maps to `--aa-eq`)
- FDR controls: `--precursor_qvalue`, `--matrix_qvalue`, `--matrix_spec_q` replacing the misleadingly named `protein_level_fdr_cutoff`
- Channel normalization flags: `--channel_run_norm`, `--channel_spec_norm` for multiplexing workflows (plexDIA/SILAC)
- InfinDIA support: `--enable_infin_dia`, `--pre_select` for ultra-large search spaces (DIA-NN >= 2.3.0)
- Fragment-level export: `--export_quant` for parquet fragment data (DIA-NN >= 2.0)
- MS1 PTM quantification: `--site_ms1_quant` (DIA-NN >= 2.0)
- Skip preliminary analysis: `--skip_preliminary_analysis` to use a provided spectral library directly
- Centralized blocked-flags registry (`lib/BlockedFlags.groovy`) with documented rationale for each blocked flag
- Version guards for all DIA-NN version-dependent features with clear error messages
- `VersionUtils.groovy` for semantic version comparison (replaces fragile string comparisons)
- Log capture via `tee` fallback in all DIA-NN modules for robust log handling across versions
- CI: `test_dda` and `test_dia_skip_preanalysis` test profiles
- `CITATION.cff` for standardized citation metadata

### `Changed`

- Removed `diann_` prefix from all user-facing parameters (e.g., `--diann_report_decoys` → `--report_decoys`, `--diann_normalize` → `--normalize`)
- Removed `diann_no_peptidoforms` parameter (superseded by `--scoring_mode`)
- Separated FINAL_QUANTIFICATION report output into parquet and TSV channels (DIA-NN >= 1.9 produces parquet)
- Matrix/stats outputs in FINAL_QUANTIFICATION now `optional: true` for DIA-NN 2.x compatibility
- Decoupled container engine from DIA-NN version configs (engine selected via `-profile`, not version config)
- Removed hardcoded DIA-NN container from `pride_codon_slurm.config`
- `--parent` flag blocked in all DIA-NN modules (container-managed model path)
- Updated Zenodo DOI to 10.5281/zenodo.19437128

### `Removed`

- `tdf2mzml` module and all references (Bruker .d files handled natively by DIA-NN >= 2.0)
- `protein_level_fdr_cutoff` parameter (replaced by `precursor_qvalue`)
- `diann_no_peptidoforms` parameter (replaced by `scoring_mode`)

### `Fixed`

- DIA-NN log file handling for versions >= 2.x that don't produce `*.log.txt` files
- `DIANN_MSSTATS` receiving both parquet and TSV when both exist (now only one format reaches downstream)
- Missing blocked flags: `--no-prot-inf` in ASSEMBLE/INDIVIDUAL/FINAL, `--channel-run-norm`/`--channel-spec-norm` in FINAL, `--var-mod`/`--fixed-mod`/`--channels` in INSILICO
- Unnecessary `.first()` warning on `ch_sdrf` value channel
- `--out` added to in-silico library generation to produce a log file with DIA-NN 2.3.2
- Calibration log parsing updated for DIA-NN 2.5.0 format changes

### `Dependencies`

| Dependency            | Version   |
| --------------------- | --------- |
| `nextflow`            | >=25.04.0 |
| `dia-nn`              | 1.8.1+    |
| `thermorawfileparser` | 2.0.0.dev |
| `sdrf-pipelines`      | 0.1.2     |
| `pmultiqc`            | 0.0.44    |
| `quantms-utils`       | 0.0.29    |

---

## [1.0.0] bigbio/quantmsdiann - 2026-04-03

Initial release of the standalone DIA-NN quantitative proteomics pipeline, refactored from [bigbio/quantms](https://github.com/bigbio/quantms).

### `Added`

- Complete DIA-NN-based proteomics analysis pipeline built following nf-core guidelines
- Multi-format input support: Thermo RAW, mzML, Bruker .d, and .dia files
- DIA-NN version management with support for versions 1.8.1, 2.1.0, and 2.2.0
- In-silico spectral library generation with configurable parameters
- Preliminary analysis with automatic mass accuracy calibration
- Empirical library assembly from DIA-NN .quant files
- Individual file analysis with per-file DIA-NN settings from SDRF
- Final quantification with protein-group, precursor, and gene-group matrices
- MSstats-compatible output generation (format conversion, no MSstats analysis)
- Quality control reporting via pmultiqc with interactive dashboards
- SDRF-driven experimental design with automatic parameter extraction
- Comprehensive CI/CD with test profiles for multiple DIA-NN versions

### `Dependencies`

| Dependency            | Version   |
| --------------------- | --------- |
| `nextflow`            | >=25.04.0 |
| `dia-nn`              | 1.8.1     |
| `thermorawfileparser` | 2.0.0.dev |
| `sdrf-pipelines`      | 0.1.2     |
| `pmultiqc`            | 0.0.43    |
| `quantms-utils`       | 0.0.28    |
