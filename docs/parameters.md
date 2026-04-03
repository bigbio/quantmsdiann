# Pipeline Parameters

Complete reference for all `bigbio/quantmsdiann` pipeline parameters.
Parameters are specified on the command line as `--parameter_name value` or
in a Nextflow config file.

## Input/Output Options

| Parameter            | Type   | Default     | Description                                                                                                                                                                             |
| -------------------- | ------ | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--input`            | string | `null`      | Path or URI to an SDRF file (.sdrf, .tsv, or .csv). Acquisition method, labelling type, enzyme, and fixed modifications are read exclusively from the SDRF.                             |
| `--database`         | string | `null`      | Path to the FASTA protein database. Must not contain decoys for DIA data.                                                                                                               |
| `--outdir`           | string | `./results` | Output directory where results will be saved.                                                                                                                                           |
| `--publish_dir_mode` | string | `copy`      | Method used to save pipeline results. Options: `symlink`, `rellink`, `link`, `copy`, `copyNoFollow`, `move`.                                                                            |
| `--root_folder`      | string | `null`      | Root folder in which spectrum files specified in the SDRF are searched. Used when files are available locally.                                                                          |
| `--local_input_type` | string | `mzML`      | Override the file type/extension of filenames in the SDRF when using `--root_folder`. Options: `mzML`, `raw`, `d`, `dia`. Compressed variants (.gz, .tar, .tar.gz, .zip) are supported. |

## SDRF Validation

| Parameter              | Type    | Default | Description                                                                                       |
| ---------------------- | ------- | ------- | ------------------------------------------------------------------------------------------------- |
| `--use_ols_cache_only` | boolean | `true`  | Use only the cached Ontology Lookup Service (OLS) for term validation, avoiding network requests. |

## File Preparation

| Parameter           | Type    | Default | Description                                                                                                                     |
| ------------------- | ------- | ------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `--reindex_mzml`    | boolean | `true`  | Force re-indexing of input mzML files at the start of the pipeline. Also fixes common issues in slightly incomplete mzMLs.      |
| `--mzml_statistics` | boolean | `false` | Compute MS1/MS2 statistics from mzML files. Generates `*_ms_info.parquet` for QC reporting. Bruker .d files are always skipped. |
| `--mzml_features`   | boolean | `false` | Compute MS1-level features during the mzML statistics step. Only available for mzML files.                                      |
| `--convert_dotd`    | boolean | `false` | Convert Bruker .d files to mzML format before processing.                                                                       |

## Search Parameters

| Parameter                         | Type    | Default         | Description                                                                                                                                |
| --------------------------------- | ------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `--met_excision`                  | boolean | `true`          | Account for N-terminal methionine excision during database search.                                                                         |
| `--allowed_missed_cleavages`      | integer | `2`             | Maximum number of allowed missed enzyme cleavages per peptide.                                                                             |
| `--precursor_mass_tolerance`      | integer | `5`             | Precursor mass tolerance for database search. See also `--precursor_mass_tolerance_unit`. Can be overridden from SDRF.                     |
| `--precursor_mass_tolerance_unit` | string  | `ppm`           | Unit for precursor mass tolerance. Options: `ppm`, `Da`.                                                                                   |
| `--fragment_mass_tolerance`       | number  | `0.03`          | Fragment mass tolerance for database search. Can be overridden from SDRF.                                                                  |
| `--fragment_mass_tolerance_unit`  | string  | `Da`            | Unit for fragment mass tolerance. Options: `ppm`, `Da`.                                                                                    |
| `--variable_mods`                 | string  | `Oxidation (M)` | Comma-separated list of variable modifications using Unimod names (e.g. `Oxidation (M),Carbamidomethyl (C)`). Can be overridden from SDRF. |
| `--min_precursor_charge`          | integer | `2`             | Minimum precursor ion charge.                                                                                                              |
| `--max_precursor_charge`          | integer | `4`             | Maximum precursor ion charge.                                                                                                              |
| `--min_peptide_length`            | integer | `6`             | Minimum peptide length to consider.                                                                                                        |
| `--max_peptide_length`            | integer | `40`            | Maximum peptide length to consider.                                                                                                        |
| `--max_mods`                      | integer | `3`             | Maximum number of modifications per peptide. Large values may slow the search considerably.                                                |
| `--min_pr_mz`                     | number  | `400`           | Minimum precursor m/z for in-silico library generation or library-free search.                                                             |
| `--max_pr_mz`                     | number  | `2400`          | Maximum precursor m/z for in-silico library generation or library-free search.                                                             |
| `--min_fr_mz`                     | number  | `100`           | Minimum fragment m/z for in-silico library generation or library-free search.                                                              |
| `--max_fr_mz`                     | number  | `1800`          | Maximum fragment m/z for in-silico library generation or library-free search.                                                              |

## DIA-NN General

| Parameter                | Type    | Default | Description                                                                                                                                   |
| ------------------------ | ------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `--diann_version`        | string  | `1.8.1` | DIA-NN version used by the workflow. Controls version-dependent flags (e.g. `--monitor-mod` for 1.8.x).                                       |
| `--diann_debug`          | integer | `3`     | DIA-NN debug/verbosity level. Allowed values: 0, 1, 2, 3, 4.                                                                                  |
| `--diann_speclib`        | string  | `null`  | Path to an existing spectral library. If provided, the pipeline uses it instead of predicting one from the FASTA.                             |
| `--diann_extra_args`     | string  | `null`  | Extra command-line arguments appended to all DIA-NN steps. Flags incompatible with a specific step are automatically stripped with a warning. |
| `--diann_dda`            | boolean | `false` | Enable DDA (Data-Dependent Acquisition) analysis mode. Passes `--dda` to all DIA-NN steps. Requires DIA-NN >= 2.3.2. Beta feature.            |
| `--diann_light_models`   | boolean | `false` | Enable `--light-models` for 10x faster in-silico library generation. Requires DIA-NN >= 2.0.                                                  |
| `--diann_export_quant`   | boolean | `false` | Enable `--export-quant` for fragment-level parquet data export. Requires DIA-NN >= 2.0.                                                       |
| `--diann_site_ms1_quant` | boolean | `false` | Enable `--site-ms1-quant` to use MS1 apex intensities for PTM site quantification. Requires DIA-NN >= 2.0.                                    |

## Mass Accuracy and Calibration

| Parameter                 | Type    | Default | Description                                                                                                     |
| ------------------------- | ------- | ------- | --------------------------------------------------------------------------------------------------------------- |
| `--mass_acc_automatic`    | boolean | `true`  | Automatically determine the MS2 mass accuracy setting.                                                          |
| `--mass_acc_ms1`          | number  | `15`    | MS1 mass accuracy in ppm. Overrides automatic calibration when set. Maps to DIA-NN `--mass-acc-ms1`.            |
| `--mass_acc_ms2`          | number  | `15`    | MS2 mass accuracy in ppm. Overrides automatic calibration when set. Maps to DIA-NN `--mass-acc`.                |
| `--scan_window`           | integer | `8`     | Scan window radius. Ideally approximately equal to the average number of data points per peak.                  |
| `--scan_window_automatic` | boolean | `true`  | Automatically determine the scan window setting.                                                                |
| `--quick_mass_acc`        | boolean | `true`  | Use a fast heuristic algorithm instead of ID-number optimization when choosing MS2 mass accuracy automatically. |
| `--performance_mode`      | boolean | `true`  | Enable low-RAM/high-speed mode. Adds `--min-corr 2 --corr-diff 1 --time-corr-only` to DIA-NN.                   |

## Bruker/timsTOF

| Parameter           | Type    | Default | Description                                                                                             |
| ------------------- | ------- | ------- | ------------------------------------------------------------------------------------------------------- |
| `--diann_tims_sum`  | boolean | `false` | Enable `--quant-tims-sum` for slice/scanning timsTOF methods. Highly recommended for Synchro-PASEF.     |
| `--diann_im_window` | number  | `null`  | Set `--im-window` to ensure the ion mobility extraction window is not smaller than the specified value. |

## PTM Localization

| Parameter                   | Type    | Default                               | Description                                                                                           |
| --------------------------- | ------- | ------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `--enable_mod_localization` | boolean | `false`                               | Enable modification localization scoring in DIA-NN (`--monitor-mod`).                                 |
| `--mod_localization`        | string  | `Phospho (S),Phospho (T),Phospho (Y)` | Comma-separated modification names or UniMod accessions for localization (e.g. `UniMod:21,UniMod:1`). |

## Library Generation

| Parameter            | Type    | Default | Description                                                                                                 |
| -------------------- | ------- | ------- | ----------------------------------------------------------------------------------------------------------- |
| `--save_speclib_tsv` | boolean | `false` | Publish the human-readable TSV spectral library from the in-silico generation step to the output directory. |

## Preliminary Analysis

| Parameter                     | Type    | Default | Description                                                                                                                          |
| ----------------------------- | ------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `--skip_preliminary_analysis` | boolean | `false` | Skip the preliminary analysis step and use the provided spectral library as-is instead of building a local consensus library.        |
| `--empirical_assembly_log`    | string  | `null`  | Path to a pre-existing empirical assembly log file. Only used when `--skip_preliminary_analysis true` and `--diann_speclib` are set. |
| `--random_preanalysis`        | boolean | `false` | Enable random selection of spectrum files for empirical library generation.                                                          |
| `--random_preanalysis_seed`   | integer | `42`    | Random seed for spectrum file selection when `--random_preanalysis` is enabled.                                                      |
| `--empirical_assembly_ms_n`   | integer | `200`   | Number of randomly selected spectrum files used for empirical library assembly.                                                      |

## Quantification and Output

| Parameter                 | Type    | Default | Description                                                                                                        |
| ------------------------- | ------- | ------- | ------------------------------------------------------------------------------------------------------------------ |
| `--pg_level`              | integer | `2`     | Protein inference mode. 0 = isoforms, 1 = protein names from FASTA, 2 = genes.                                     |
| `--species_genes`         | boolean | `false` | Add the organism identifier to gene names in DIA-NN output.                                                        |
| `--diann_normalize`       | boolean | `true`  | Enable cross-run normalization in DIA-NN.                                                                          |
| `--diann_report_decoys`   | boolean | `false` | Include decoy PSMs in the main .parquet report.                                                                    |
| `--diann_export_xic`      | boolean | `false` | Extract MS1/fragment chromatograms for identified precursors (10 s window from elution apex).                      |
| `--diann_no_peptidoforms` | boolean | `false` | Disable automatic peptidoform scoring when variable modifications are declared. Not recommended by DIA-NN authors. |
| `--diann_use_quant`       | boolean | `true`  | Reuse existing .quant files if available during final quantification (`--use-quant`).                              |
| `--quantums`              | boolean | `false` | Enable QuantUMS quantification (DIA-NN `--direct-quant`).                                                          |
| `--quantums_train_runs`   | string  | `null`  | Run index range for QuantUMS training (e.g. `0:5`). Maps to `--quant-train-runs`.                                  |
| `--quantums_sel_runs`     | integer | `null`  | Number of automatically selected runs for QuantUMS training. Must be >= 6. Maps to `--quant-sel-runs`.             |
| `--quantums_params`       | string  | `null`  | Pre-calculated QuantUMS parameters. Maps to `--quant-params`.                                                      |

## DDA Mode

| Parameter     | Type    | Default | Description                                                                                                                                                                                                   |
| ------------- | ------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--diann_dda` | boolean | `false` | Enable DDA analysis mode. Passes `--dda` to all DIA-NN steps. Requires DIA-NN >= 2.3.2 (use `-profile diann_v2_3_2`). This is a beta feature with known limitations; see the usage documentation for details. |

> **Note:** DDA support requires DIA-NN >= 2.3.2. Enable this profile with
> `-profile diann_v2_3_2`. The DDA mode is experimental and may not support
> all pipeline features available in DIA mode.

## InfinDIA (Experimental)

| Parameter            | Type    | Default | Description                                                                            |
| -------------------- | ------- | ------- | -------------------------------------------------------------------------------------- |
| `--enable_infin_dia` | boolean | `false` | Enable InfinDIA for ultra-large search spaces. Requires DIA-NN >= 2.3.0. Experimental. |
| `--diann_pre_select` | integer | `null`  | Precursor limit (`--pre-select N`) for InfinDIA pre-search.                            |

> **Note:** InfinDIA requires DIA-NN >= 2.3.0 and is considered experimental.

## Quality Control

| Parameter                    | Type    | Default | Description                                                                          |
| ---------------------------- | ------- | ------- | ------------------------------------------------------------------------------------ |
| `--enable_pmultiqc`          | boolean | `true`  | Generate a pmultiqc proteomics QC report.                                            |
| `--pmultiqc_idxml_skip`      | boolean | `true`  | Skip idXML files (do not generate search engine score plots) in the pmultiqc report. |
| `--contaminant_string`       | string  | `CONT`  | Contaminant affix string used by pmultiqc to identify contaminant proteins.          |
| `--protein_level_fdr_cutoff` | number  | `0.01`  | Experiment-wide protein/protein-group-level FDR cutoff.                              |

## MultiQC

| Parameter                       | Type    | Default | Description                                                                                |
| ------------------------------- | ------- | ------- | ------------------------------------------------------------------------------------------ |
| `--multiqc_config`              | string  | `null`  | Path to a custom MultiQC configuration file.                                               |
| `--multiqc_title`               | string  | `null`  | Custom title for the MultiQC report. Used as page header and default filename.             |
| `--multiqc_logo`                | string  | `null`  | Path to a custom logo file for the MultiQC report. Must also be set in the MultiQC config. |
| `--skip_table_plots`            | boolean | `false` | Skip protein/peptide table plots in pmultiqc. Useful for very large datasets.              |
| `--max_multiqc_email_size`      | string  | `25.MB` | Maximum file size for MultiQC report attachments in summary emails.                        |
| `--multiqc_methods_description` | string  | `null`  | Path to a custom YAML file containing an HTML methods description for MultiQC.             |
