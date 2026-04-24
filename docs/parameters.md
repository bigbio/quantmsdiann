# bigbio/quantmsdiann: Parameters

This document lists every pipeline parameter organised by category. Default values come from `nextflow.config`; types and constraints come from `nextflow_schema.json`.

## 1. Input/Output Options

| Parameter            | Type                    | Default     | Description                                                                                                                                                                                                                |
| -------------------- | ----------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--input`            | string (file-path)      | _required_  | URI/path to an SDRF file with `.sdrf`, `.tsv`, or `.csv` extension. Parameters such as enzyme, fixed modifications, and acquisition method are read from the SDRF.                                                         |
| `--database`         | string (file-path)      | _required_  | Path to a FASTA protein database. Must not contain decoys for DIA data.                                                                                                                                                    |
| `--outdir`           | string (directory-path) | `./results` | The output directory where results will be saved.                                                                                                                                                                          |
| `--publish_dir_mode` | string                  | `copy`      | Method used to save pipeline results. One of: `symlink`, `rellink`, `link`, `copy`, `copyNoFollow`, `move`.                                                                                                                |
| `--root_folder`      | string                  | `null`      | Root folder in which spectrum files specified in the SDRF are searched. Used when you have a local copy of the experiment.                                                                                                 |
| `--local_input_type` | string                  | `mzML`      | Overwrite the file type/extension of filenames in the SDRF when using `--root_folder`. One of: `mzML`, `raw`, `d`, `dia`. Compressed variants (`.gz`, `.tar`, `.tar.gz`, `.zip`) are supported for `mzML`, `raw`, and `d`. |
| `--email`            | string                  | `null`      | Email address for completion summary.                                                                                                                                                                                      |

## 2. SDRF Validation

| Parameter              | Type    | Default | Description                                                                                                               |
| ---------------------- | ------- | ------- | ------------------------------------------------------------------------------------------------------------------------- |
| `--use_ols_cache_only` | boolean | `true`  | Use only the cached Ontology Lookup Service (OLS) for ontology term validation. Set to `false` to allow network requests. |

## 3. File Preparation (Spectrum Preprocessing)

| Parameter           | Type    | Default | Description                                                                                                                                                                                                                                                                                  |
| ------------------- | ------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--reindex_mzml`    | boolean | `true`  | Force re-indexing of input mzML files at the start of the pipeline for safety.                                                                                                                                                                                                               |
| `--mzml_statistics` | boolean | `false` | Compute MS1/MS2 statistics from mzML files. Generates `*_ms_info.parquet` files for QC. Bruker `.d` files are always skipped.                                                                                                                                                                |
| `--mzml_features`   | boolean | `false` | Compute MS1-level features during the mzML statistics step. Only available for mzML files.                                                                                                                                                                                                   |
| `--mzml_convert`    | boolean | _auto_  | Convert Thermo `.raw` to `.mzML` via ThermoRawFileParser before DIA-NN. Unset = auto: convert when DIA-NN < 2.1.0, pass `.raw` through when DIA-NN >= 2.1.0. Set `false` to force native `.raw` (requires DIA-NN >= 2.1.0); set `true` to force conversion (e.g. to enable mzML statistics). |

## 4. Search Parameters

| Parameter                         | Type    | Default         | Description                                                                                                                                |
| --------------------------------- | ------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `--met_excision`                  | boolean | `true`          | Account for N-terminal methionine excision during database search.                                                                         |
| `--allowed_missed_cleavages`      | integer | `2`             | Maximum number of allowed missed enzyme cleavages per peptide.                                                                             |
| `--precursor_mass_tolerance`      | integer | `5`             | Precursor mass tolerance for database search (see `--precursor_mass_tolerance_unit`). Can be overridden; falls back to SDRF value.         |
| `--precursor_mass_tolerance_unit` | string  | `ppm`           | Precursor mass tolerance unit. One of: `ppm`, `Da`.                                                                                        |
| `--fragment_mass_tolerance`       | number  | `0.03`          | Fragment mass tolerance for database search (see `--fragment_mass_tolerance_unit`).                                                        |
| `--fragment_mass_tolerance_unit`  | string  | `Da`            | Fragment mass tolerance unit. One of: `ppm`, `Da`.                                                                                         |
| `--variable_mods`                 | string  | `Oxidation (M)` | Comma-separated variable modifications in Unimod format (e.g. `Oxidation (M),Carbamidomethyl (C)`). Can be overridden; falls back to SDRF. |
| `--min_precursor_charge`          | integer | `2`             | Minimum precursor ion charge.                                                                                                              |
| `--max_precursor_charge`          | integer | `4`             | Maximum precursor ion charge.                                                                                                              |
| `--min_peptide_length`            | integer | `6`             | Minimum peptide length to consider.                                                                                                        |
| `--max_peptide_length`            | integer | `40`            | Maximum peptide length to consider.                                                                                                        |
| `--max_mods`                      | integer | `3`             | Maximum number of variable modifications per peptide.                                                                                      |
| `--min_pr_mz`                     | number  | `400`           | Minimum precursor m/z for in-silico library generation or library-free search.                                                             |
| `--max_pr_mz`                     | number  | `2400`          | Maximum precursor m/z for in-silico library generation or library-free search.                                                             |
| `--min_fr_mz`                     | number  | `100`           | Minimum fragment m/z for in-silico library generation or library-free search.                                                              |
| `--max_fr_mz`                     | number  | `1800`          | Maximum fragment m/z for in-silico library generation or library-free search.                                                              |

## 5. DIA-NN General

| Parameter          | Type    | Default | Description                                                                                                                                                                                                     |
| ------------------ | ------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--diann_version`  | string  | `1.8.1` | DIA-NN version used by the workflow. Controls version-dependent flags (e.g. `--monitor-mod` for 1.8.x). See [DIA-NN Version Selection](usage.md#dia-nn-version-selection).                                      |
| `--debug_level`    | integer | `3`     | DIA-NN debug/verbosity level (0-4). Higher values produce more verbose logs.                                                                                                                                    |
| `--speclib`        | string  | `null`  | Path to an external spectral library. If provided, the in-silico library generation step is skipped.                                                                                                            |
| `--extra_args`     | string  | `null`  | Extra arguments appended to all DIA-NN steps. Flags incompatible with a step are automatically stripped with a warning. See [Passing Extra Arguments to DIA-NN](usage.md#passing-extra-arguments-to-dia-nn).    |
| `--dda`            | boolean | `false` | Explicitly enable DDA mode. Normally auto-detected from the SDRF `comment[proteomics data acquisition method]` column. Use this flag only when the SDRF lacks the acquisition method. Requires DIA-NN >= 2.3.2. |
| `--light_models`   | boolean | `false` | Enable `--light-models` for 10x faster in-silico library generation. Requires DIA-NN >= 2.0.                                                                                                                    |
| `--export_quant`   | boolean | `false` | Enable `--export-quant` for fragment-level parquet data export. Requires DIA-NN >= 2.0.                                                                                                                         |
| `--site_ms1_quant` | boolean | `false` | Enable `--site-ms1-quant` to use MS1 apex intensities for PTM site quantification. Requires DIA-NN >= 2.0.                                                                                                      |
| `--aa_eq`          | boolean | `false` | Treat I&L, Q&E, N&D as equivalent amino acids during reannotation. Essential for entrapment FDR benchmarks. Maps to `--aa-eq`.                                                                                  |

### DIA-NN 2.5.0 flags (via `--extra_args`)

The following DIA-NN 2.5.0 flags are not exposed as pipeline parameters but can be passed via `--extra_args`. See [Fine-Tuning Deep Learning Models](usage.md#fine-tuning-deep-learning-models-dia-nn-20) for the complete workflow.

| DIA-NN flag              | Description                                                                                      |
| ------------------------ | ------------------------------------------------------------------------------------------------ |
| `--tokens <file>`        | Tokenizer dictionary mapping modified residues to neural network token IDs (0-255).              |
| `--rt-model <file>`      | Fine-tuned retention time prediction model (`.pt` PyTorch file).                                 |
| `--fr-model <file>`      | Fine-tuned fragment ion prediction model (`.pt` file). Quality-sensitive — verify vs base model. |
| `--im-model <file>`      | Fine-tuned ion mobility prediction model (`.pt` file).                                           |
| `--tune-lib <file>`      | Spectral library for fine-tuning (`.parquet`). Requires `--tune-rt` and/or `--tune-im`.          |
| `--tune-rt`              | Fine-tune the RT deep learning predictor. Requires `--tune-lib`.                                 |
| `--tune-im`              | Fine-tune the IM deep learning predictor. Requires `--tune-lib`.                                 |
| `--tune-fr`              | Fine-tune the fragmentation predictor. Requires `--tune-lib`. Use with caution.                  |
| `--tune-lr <X>`          | Fine-tuning learning rate (default: 0.0005).                                                     |
| `--tune-restrict-layers` | Keep RNN layer weights fixed during fine-tuning (except cysteine embeddings).                    |
| `--tune-level <N>`       | Limit fine-tuning to a specific model distillation level (0, 1, or 2).                           |

> **Note:** `--parent` and `--aa-eq` are blocked from `--extra_args` — they are managed as pipeline parameters (`--aa_eq`). `--parent` is container-managed and overriding it would break model discovery.

## 6. Mass Accuracy & Calibration

| Parameter                 | Type    | Default | Description                                                                                                                   |
| ------------------------- | ------- | ------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `--mass_acc_automatic`    | boolean | `true`  | Automatically determine MS2 mass accuracy. When `true`, `--mass_acc_ms2` is ignored during preliminary analysis.              |
| `--mass_acc_ms1`          | number  | `15`    | MS1 mass accuracy in ppm. Overrides automatic calibration when `--mass_acc_automatic false`. Maps to DIA-NN `--mass-acc-ms1`. |
| `--mass_acc_ms2`          | number  | `15`    | MS2 mass accuracy in ppm. Overrides automatic calibration when `--mass_acc_automatic false`. Maps to DIA-NN `--mass-acc`.     |
| `--scan_window`           | integer | `8`     | Scan window radius. Should approximate the average number of data points per peak.                                            |
| `--scan_window_automatic` | boolean | `true`  | Automatically determine the scan window. When `true`, `--scan_window` is ignored.                                             |
| `--quick_mass_acc`        | boolean | `true`  | Use a fast heuristic algorithm for mass accuracy calibration instead of ID-number optimisation.                               |
| `--performance_mode`      | boolean | `true`  | Enable low-RAM, high-speed mode. Adds `--min-corr 2 --corr-diff 1 --time-corr-only` to DIA-NN.                                |

## 7. Bruker/timsTOF

| Parameter     | Type    | Default | Description                                                                                          |
| ------------- | ------- | ------- | ---------------------------------------------------------------------------------------------------- |
| `--tims_sum`  | boolean | `false` | Enable `--quant-tims-sum` for slice/scanning timsTOF methods (highly recommended for Synchro-PASEF). |
| `--im_window` | number  | `null`  | Set `--im-window` to ensure the IM extraction window is not smaller than the specified value.        |

## 8. PTM Localization

| Parameter                   | Type    | Default                               | Description                                                                                                    |
| --------------------------- | ------- | ------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `--enable_mod_localization` | boolean | `false`                               | Enable modification localization scoring in DIA-NN via `--monitor-mod` (DIA-NN 1.8.x only; automatic in 2.0+). |
| `--mod_localization`        | string  | `Phospho (S),Phospho (T),Phospho (Y)` | Comma-separated modification names or UniMod accessions for PTM localization (e.g. `UniMod:21`).               |

## 9. Library Generation

| Parameter            | Type    | Default | Description                                                                                  |
| -------------------- | ------- | ------- | -------------------------------------------------------------------------------------------- |
| `--save_speclib_tsv` | boolean | `false` | Publish the TSV spectral library from in-silico library generation to `library_generation/`. |

## 10. Preliminary Analysis

| Parameter                     | Type    | Default | Description                                                                                                                    |
| ----------------------------- | ------- | ------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `--skip_preliminary_analysis` | boolean | `false` | Skip preliminary analysis. Use the provided spectral library as-is instead of generating a local consensus library.            |
| `--empirical_assembly_log`    | string  | `null`  | Path to a pre-existing empirical assembly log file. Only used when `--skip_preliminary_analysis true` and `--speclib` are set. |
| `--random_preanalysis`        | boolean | `false` | Enable random selection of spectrum files for empirical library generation.                                                    |
| `--random_preanalysis_seed`   | integer | `42`    | Random seed for file selection when `--random_preanalysis` is enabled.                                                         |
| `--empirical_assembly_ms_n`   | integer | `200`   | Number of randomly selected spectrum files when `--random_preanalysis` is enabled.                                             |

## 11. Quantification & Output

| Parameter               | Type    | Default   | Description                                                                                                                                                                                                                            |
| ----------------------- | ------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--pg_level`            | integer | `2`       | Protein inference mode. `0` = isoforms, `1` = protein names (from FASTA), `2` = genes (default).                                                                                                                                       |
| `--species_genes`       | boolean | `false`   | Add the organism identifier to gene names in DIA-NN output.                                                                                                                                                                            |
| `--normalize`           | boolean | `true`    | Enable cross-run normalisation in DIA-NN. Set to `false` to add `--no-norm`.                                                                                                                                                           |
| `--report_decoys`       | boolean | `false`   | Include decoy PSMs in the main `.parquet` report (DIA-NN 2.0+ only).                                                                                                                                                                   |
| `--export_xic`          | boolean | `false`   | Extract MS1/fragment chromatograms for identified precursors (equivalent to the XICs option in the DIA-NN GUI).                                                                                                                        |
| `--scoring_mode`        | string  | `generic` | DIA-NN scoring mode: `generic` (default, maximizes IDs), `proteoforms` (recommended for proteogenomics/variant detection, requires >= 2.0), `peptidoforms` (extra q-values for PTM analysis).                                          |
| `--use_quant`           | boolean | `true`    | Reuse existing `.quant` files if available (`--use-quant`).                                                                                                                                                                            |
| `--quantums`            | boolean | `false`   | Enable QuantUMS quantification (requires DIA-NN >= 1.9.2). When `false`, the pipeline passes `--direct-quant` to use legacy quantification (only for DIA-NN >= 1.9.2; silently skipped for 1.8.x where direct quant is the only mode). |
| `--quantums_train_runs` | string  | `null`    | Run index range for QuantUMS training (e.g. `0:5`). Maps to `--quant-train-runs`. Requires DIA-NN >= 1.9.2.                                                                                                                            |
| `--quantums_sel_runs`   | integer | `null`    | Number of automatically selected runs for QuantUMS training. Must be >= 6. Maps to `--quant-sel-runs`. Requires DIA-NN >= 1.9.2.                                                                                                       |
| `--quantums_params`     | string  | `null`    | Pre-calculated QuantUMS parameters. Maps to `--quant-params`. Requires DIA-NN >= 1.9.2.                                                                                                                                                |

## 12. DDA Mode

| Parameter | Type    | Default | Description                                                                                                                                                                                                                                |
| --------- | ------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `--dda`   | boolean | `false` | Explicitly enable DDA mode when SDRF lacks the acquisition method column. Normally DDA is auto-detected from the SDRF `comment[proteomics data acquisition method]`. Requires DIA-NN >= 2.3.2 (use `-profile diann_v2_3_2`). Beta feature. |

> **Note:** DDA mode is auto-detected from the SDRF when the `comment[proteomics data acquisition method]`
> column contains `data-dependent acquisition`. The `--dda` flag is only needed as a
> fallback when the SDRF does not include this column. DDA requires DIA-NN >= 2.3.2
> (`-profile diann_v2_3_2`).

## 13. InfinDIA (Experimental)

| Parameter            | Type    | Default | Description                                                                            |
| -------------------- | ------- | ------- | -------------------------------------------------------------------------------------- |
| `--enable_infin_dia` | boolean | `false` | Enable InfinDIA for ultra-large search spaces. Requires DIA-NN >= 2.3.0. Experimental. |
| `--pre_select`       | integer | `null`  | Precursor limit (`--pre-select N`) for InfinDIA pre-search.                            |

> **Note:** InfinDIA requires DIA-NN >= 2.3.0 and is considered experimental.

## 14. Quality Control

| Parameter               | Type    | Default | Description                                                                                     |
| ----------------------- | ------- | ------- | ----------------------------------------------------------------------------------------------- |
| `--enable_pmultiqc`     | boolean | `true`  | Generate the pmultiqc QC report.                                                                |
| `--pmultiqc_idxml_skip` | boolean | `true`  | Skip idXML files (do not generate search engine score plots) in the pmultiqc report.            |
| `--contaminant_string`  | string  | `CONT`  | Contaminant affix string for pmultiqc. Maps to `--contaminant_affix` in pmultiqc.               |
| `--precursor_qvalue`    | number  | `0.01`  | Precursor-level q-value threshold for the DIA-NN main report. Maps to `--qvalue`.               |
| `--matrix_qvalue`       | number  | `0.01`  | Q-value threshold for DIA-NN output matrices (pr_matrix, pg_matrix). Maps to `--matrix-qvalue`. |
| `--matrix_spec_q`       | number  | `0.05`  | Run-specific protein q-value for protein/gene matrices. Maps to `--matrix-spec-q`.              |

## 15. MultiQC & Reporting

| Parameter                       | Type               | Default | Description                                                                       |
| ------------------------------- | ------------------ | ------- | --------------------------------------------------------------------------------- |
| `--multiqc_config`              | string (file-path) | `null`  | Custom config file to supply to MultiQC.                                          |
| `--multiqc_title`               | string             | `null`  | MultiQC report title. Used as page header and filename.                           |
| `--multiqc_logo`                | string             | `null`  | Custom logo file for MultiQC. Must also be referenced in the MultiQC config file. |
| `--skip_table_plots`            | boolean            | `false` | Skip protein/peptide table plots in pmultiqc for large datasets.                  |
| `--max_multiqc_email_size`      | string             | `25.MB` | File size limit when attaching MultiQC reports to summary emails.                 |
| `--multiqc_methods_description` | string             | `null`  | Custom MultiQC YAML file containing an HTML methods description.                  |
