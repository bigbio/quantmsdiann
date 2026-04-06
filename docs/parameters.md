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

| Parameter           | Type    | Default | Description                                                                                                                   |
| ------------------- | ------- | ------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `--reindex_mzml`    | boolean | `true`  | Force re-indexing of input mzML files at the start of the pipeline for safety.                                                |
| `--mzml_statistics` | boolean | `false` | Compute MS1/MS2 statistics from mzML files. Generates `*_ms_info.parquet` files for QC. Bruker `.d` files are always skipped. |
| `--mzml_features`   | boolean | `false` | Compute MS1-level features during the mzML statistics step. Only available for mzML files.                                    |

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

| Parameter            | Type    | Default | Description                                                                                                                                                                                                  |
| -------------------- | ------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `--diann_version`    | string  | `1.8.1` | DIA-NN version used by the workflow. Controls version-dependent flags (e.g. `--monitor-mod` for 1.8.x). See [DIA-NN Version Selection](usage.md#dia-nn-version-selection).                                   |
| `--diann_debug`      | integer | `3`     | DIA-NN debug/verbosity level (0-4). Higher values produce more verbose logs.                                                                                                                                 |
| `--diann_speclib`    | string  | `null`  | Path to an external spectral library. If provided, the in-silico library generation step is skipped.                                                                                                         |
| `--diann_extra_args` | string  | `null`  | Extra arguments appended to all DIA-NN steps. Flags incompatible with a step are automatically stripped with a warning. See [Passing Extra Arguments to DIA-NN](usage.md#passing-extra-arguments-to-dia-nn). |

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

| Parameter           | Type    | Default | Description                                                                                          |
| ------------------- | ------- | ------- | ---------------------------------------------------------------------------------------------------- |
| `--diann_tims_sum`  | boolean | `false` | Enable `--quant-tims-sum` for slice/scanning timsTOF methods (highly recommended for Synchro-PASEF). |
| `--diann_im_window` | number  | `null`  | Set `--im-window` to ensure the IM extraction window is not smaller than the specified value.        |

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

| Parameter                     | Type    | Default | Description                                                                                                         |
| ----------------------------- | ------- | ------- | ------------------------------------------------------------------------------------------------------------------- |
| `--skip_preliminary_analysis` | boolean | `false` | Skip preliminary analysis. Use the provided spectral library as-is instead of generating a local consensus library. |
| `--random_preanalysis`        | boolean | `false` | Enable random selection of spectrum files for empirical library generation.                                         |
| `--random_preanalysis_seed`   | integer | `42`    | Random seed for file selection when `--random_preanalysis` is enabled.                                              |
| `--empirical_assembly_ms_n`   | integer | `200`   | Number of randomly selected spectrum files when `--random_preanalysis` is enabled.                                  |

## 11. Quantification & Output

| Parameter                 | Type    | Default | Description                                                                                                                                                                                                                            |
| ------------------------- | ------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--pg_level`              | integer | `2`     | Protein inference mode. `0` = isoforms, `1` = protein names (from FASTA), `2` = genes (default).                                                                                                                                       |
| `--species_genes`         | boolean | `false` | Add the organism identifier to gene names in DIA-NN output.                                                                                                                                                                            |
| `--diann_normalize`       | boolean | `true`  | Enable cross-run normalisation in DIA-NN. Set to `false` to add `--no-norm`.                                                                                                                                                           |
| `--diann_report_decoys`   | boolean | `false` | Include decoy PSMs in the main `.parquet` report (DIA-NN 2.0+ only).                                                                                                                                                                   |
| `--diann_export_xic`      | boolean | `false` | Extract MS1/fragment chromatograms for identified precursors (equivalent to the XICs option in the DIA-NN GUI).                                                                                                                        |
| `--diann_no_peptidoforms` | boolean | `false` | Disable automatic peptidoform scoring when variable modifications are declared (not recommended by DIA-NN).                                                                                                                            |
| `--diann_use_quant`       | boolean | `true`  | Reuse existing `.quant` files if available (`--use-quant`).                                                                                                                                                                            |
| `--quantums`              | boolean | `false` | Enable QuantUMS quantification (requires DIA-NN >= 1.9.2). When `false`, the pipeline passes `--direct-quant` to use legacy quantification (only for DIA-NN >= 1.9.2; silently skipped for 1.8.x where direct quant is the only mode). |
| `--quantums_train_runs`   | string  | `null`  | Run index range for QuantUMS training (e.g. `0:5`). Maps to `--quant-train-runs`. Requires DIA-NN >= 1.9.2.                                                                                                                            |
| `--quantums_sel_runs`     | integer | `null`  | Number of automatically selected runs for QuantUMS training. Must be >= 6. Maps to `--quant-sel-runs`. Requires DIA-NN >= 1.9.2.                                                                                                       |
| `--quantums_params`       | string  | `null`  | Pre-calculated QuantUMS parameters. Maps to `--quant-params`. Requires DIA-NN >= 1.9.2.                                                                                                                                                |

## 12. Quality Control

| Parameter                    | Type    | Default | Description                                                                          |
| ---------------------------- | ------- | ------- | ------------------------------------------------------------------------------------ |
| `--enable_pmultiqc`          | boolean | `true`  | Generate the pmultiqc QC report.                                                     |
| `--pmultiqc_idxml_skip`      | boolean | `true`  | Skip idXML files (do not generate search engine score plots) in the pmultiqc report. |
| `--contaminant_string`       | string  | `CONT`  | Contaminant affix string for pmultiqc. Maps to `--contaminant_affix` in pmultiqc.    |
| `--protein_level_fdr_cutoff` | number  | `0.01`  | Experiment-wide protein (group)-level FDR cutoff.                                    |

## 13. MultiQC & Reporting

| Parameter                       | Type               | Default | Description                                                                       |
| ------------------------------- | ------------------ | ------- | --------------------------------------------------------------------------------- |
| `--multiqc_config`              | string (file-path) | `null`  | Custom config file to supply to MultiQC.                                          |
| `--multiqc_title`               | string             | `null`  | MultiQC report title. Used as page header and filename.                           |
| `--multiqc_logo`                | string             | `null`  | Custom logo file for MultiQC. Must also be referenced in the MultiQC config file. |
| `--skip_table_plots`            | boolean            | `false` | Skip protein/peptide table plots in pmultiqc for large datasets.                  |
| `--max_multiqc_email_size`      | string             | `25.MB` | File size limit when attaching MultiQC reports to summary emails.                 |
| `--multiqc_methods_description` | string             | `null`  | Custom MultiQC YAML file containing an HTML methods description.                  |
