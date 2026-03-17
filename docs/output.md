# bigbio/quantmsdiann: Output

## Introduction

This document describes the output produced by the pipeline. Most plots are taken from the pMultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps for DDA-LFQ and DDA-ISO data:

For DIA-LFQ experiments, the workflow is different:

1. RAW data is converted to mzML using the ThermoRawFileParser
2. DIA-NN is used for identification and quantification of the peptides and proteins
3. Generation of output files
4. Generation of QC reports using pMultiQC, a library for QC proteomics data analysis.

## Output structure

Output will be saved to the folder defined by the parameter `--outdir`. Each step of the workflow exports different files and reports with the specific data, peptide identifications, protein quantifications, etc. Most of the pipeline outputs are [HUPO-PSI](https://www.psidev.info/) standard file formats:

- [mzML](https://www.psidev.info/mzML): The mzML format is an open, XML-based format for mass spectrometer output files.
- [mzTab](https://www.psidev.info/mztab): mzTab is intended as a lightweight tab-delimited file format to export peptide and protein identification/quantification results.

### Default Output Structure

By default, quantms organizes output files in a structured way, with specific directories for different types of outputs. The structure varies slightly depending on the workflow type (DIA, ISO, LFQ, etc.), but follows a consistent organization pattern.

#### Common directories across all workflows:

- `pipeline_info/`: Contains Nextflow pipeline information, execution reports, and software versions
- `sdrf/`: Contains SDRF files, OpenMS configs, and other experimental design files
- `pmultiqc/`: Contains pMultiQC reports and visualizations
  - `multiqc_data/`: Raw data used by pMultiQC
  - `multiqc_plots/`: Visualizations in different formats
    - `png/`: PNG format plots
    - `svg/`: SVG format plots
    - `pdf/`: PDF format plots

#### DIA workflow output structure:

```
results_dia/
├── pipeline_info/             # Nextflow pipeline information
├── sdrf/                      # SDRF files and configs
├── spectra/                   # Spectra-related data (only present if --mzml_features is enabled)
    ├──thermorawfileparser/    # Converted raw files
├── quant_tables/              # Quantification tables and results
├── msstats/                   # MSstats processed results
└── pmultiqc/                  # pMultiQC reports
    ├── multiqc_plots/
    │   ├── png/
    │   ├── svg/
    │   └── pdf/
    └── multiqc_data/
```

#### Localize workflow output structure:

```
results_localize/
├── pipeline_info/             # Nextflow pipeline information
├── sdrf/                      # SDRF files and configs
├── quant_tables/              # Quantification tables and results
└── pmultiqc/                  # pMultiQC reports
    ├── multiqc_plots/
    │   ├── svg/
    │   ├── pdf/
    │   └── png/
    └── multiqc_data/
```

### Verbose Output Structure

For more detailed output with all intermediate files, you can use the verbose output configuration by providing the config parameter `-c verbose_modules` when running the pipeline. This will use the `verbose_modules` configuration. It can be useful for debugging or detailed analysis of the pipeline's steps.

For DIA workflows, the verbose output structure includes additional directories:

```
results/
├── pipeline_info/             # Nextflow pipeline information
├── sdrf/                      # SDRF files and configs
├── spectra/                   # Spectra-related data (only present if --mzml_features is enabled)
│   ├── thermorawfileparser/   # Converted raw files
│   └── mzml_statistics/       # Statistics about mzML files
├── database_generation/       # Database generation for DIA
│   ├── insilico_library_generation/  # In silico library generation
│   └── assemble_empirical_library/   # Empirical library assembly
├── diann_preprocessing/       # DIA-NN preprocessing
│   ├── preliminary_analysis/  # Preliminary analysis results
│   └── individual_analysis/   # Individual analysis results
├── quant_tables/              # Quantification tables and results
├── msstats/                   # MSstats processed results
└── pmultiqc/                  # pMultiQC reports
    ├── multiqc_plots/
    │   ├── png/
    │   ├── pdf/
    │   └── svg/
    └── multiqc_data/
```

### Key Output Files

Depending on the workflow type, the main output files will be found in the following directories:

- `quant_tables/`: Contains all quantification results including mzTab files, MSstats input files, and other quantification tables
- `psm_tables/`: Contains PSM-level results from the identification pipeline in parquet format
- `msstats/`: Contains MSstats processed results and reports
- `pmultiqc/`: Contains quality control reports and visualizations

The specific files include:

- DIA-LFQ quantification results:
  - `quant_tables/diann_report.tsv` - DIA-NN main report with peptide and protein quantification
  - `quant_tables/diann_report.pr_matrix.tsv` - Protein quantification matrix from DIA-NN
  - `quant_tables/diann_report.pg_matrix.tsv` - Protein group quantification matrix from DIA-NN
  - `quant_tables/diann_report.peptide_matrix.tsv` - Peptide quantification matrix from DIA-NN
  - `quant_tables/diann_report.lib` - DIA-NN spectral library
  - `quant_tables/out_msstats_in.csv` - [MSstats-ready](#msstats-ready-quantity-tables) quantity tables

- MSstats-processed results:
  - `msstats/out_msstats.mzTab` - [MSstats-processed](#msstats-processed-mztab) mzTab

## Output description

### Nextflow pipeline info

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.

<details markdown="1">
<summary>Output files</summary>

`pipeline_info/`:

- Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
- Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
- Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
- `params_<timestamp>.json` containing the command line provided parameters. Some parameters are overwritten if an SDRF file is used.

</details>

> Note. These parameters are overwritten if an SDRF file is used. Even if they are set
> in the parameters, the SDRF file has precedence.
>
> - labelling_type
> - dissociationmethod
> - fixedmodifications
> - variablemodifications
> - precursormasstolerance
> - precursormasstoleranceunit
> - fragmentmasstolerance
> - fragmentmasstoleranceunit
> - enzyme
> - acquisition_method


##### MSstats-ready quantity tables

MSstats output is generated for all three pipelines DDA-LFQ, DDA-ISO and DIA-LFQ. A simple tsv file ready to be read by the
OpenMStoMSstats function of the MSstats R package. It should hold the same quantities as the consensusXML but rearranged in a "long" table format with additional
information about the experimental design used by MSstats.

#### mzTab

The mzTab is exported for all three workflows DDA-LFQ, DDA-ISO and DIA-LFQ. It is a complete [mzTab](https://github.com/HUPO-PSI/mzTab) file
ready for submission to [PRIDE](https://www.ebi.ac.uk/pride/). It contains both identifications (only those responsible for a quantification),
quantities and some metadata about both the experiment and the quantification.

mzTab is a multi-section TSV file where the first column is a section identifier:

- MTD: Metadata
- PRH: Protein header line
- PRT: Protein entry line
- PEH: Peptide header line
- PEP: Peptide entry line
- PSH: Peptide-spectrum match header
- PSM: Peptide-spectrum match entry line

Some explanations for optional ("opt\_") columns:

PRT section:

- opt_global_Posterior_Probability_score: As opposed to the best_search_engine_score columns (which usually represent an FDR [consult the MTD section]) this specifies the posterior probability for a protein or protein group as calculated by protein inference.
- opt_global_nr_found_peptides: The number of found peptides for the protein (group). By default this counts unmodified peptide sequences (TODO double-check)
- opt_global_cv_PRIDE:0000303_decoy_hit: If this was a real target hit or a decoy entry added artificially to the protein database.
- opt_global_result_type:
  - single_protein: A protein that is uniquely distinguishable from others. Note: this could be a subsumable protein.
  - indistinguishable_protein_group: A group of proteins that share exactly the same set of observed peptides.
  - protein_details: A dummy entry for every protein belonging to either of the two classes above. In case of an indistinguishable group, it would otherwise not be possible to report unique sequence coverage information about each member of the group. Do not use these entries for quantitative information or scoring as they will be "null/empty". They shall only be used to extract auxiliary information if required.

PEP section:

- opt_global_cv_MS:1000889_peptidoform_sequence: The sequence of the best explanation of this feature/spectrum but with modifications.
- opt_global_feature_id: A unique ID assigned by internal algorithms. E.g., for looking up additional information in the PSM section or other output files like consensusXML
- opt_global_SpecEValue_score: Spectral E-Value for the best match for this peptide (from the MSGF search engine)
- opt_global_q-value(\_score): Experiment-wide q-value of the best match. The exact interpretation depends on the FDR/q-value settings of the pipeline.
- opt_global_cv_MS:1002217_decoy_peptide: If the peptide from the best match was a target peptide from the digest of the input protein database, or an annotated or generated decoy.
- opt_global_mass_to_charge_study_variable[n]: The m/z of the precursor (isobaric) or the feature (LFQ) in study_variable (= usually sample) n.
- opt_global_retention_time_study_variable[n]: The retention time in seconds of the precursor (isobaric) or the feature (LFQ) in study_variable (= usually sample) n.

PSM section:

- opt_global_FFId_category: Currently always "internal".
- opt_global_feature_id: A unique ID assigned by internal algorithms. E.g., for looking up additional information in the PEP section or other output files like consensusXML.
- opt_global_map_index: May be ignored. Should be a one-to-one correspondence between "ms_run" in which this PSM was found and the value in this column + 1.
- opt_global_spectrum_reference: May be ignored. Should be a one-to-one correspondence between the second part of the spectra_ref column and this column.
- opt_global_cv_MS:1000889_peptidoform_sequence: The sequence for this match including modifications.
- opt_global_SpecEValue_score: Spectral E-Value for this match (from the MSGF search engine)
- opt_global_q-value(\_score): Experiment-wide q-value. The exact interpretation depends on the FDR/q-value settings of the pipeline.
- opt_global_cv_MS:1002217_decoy_peptide: If the peptide from this match was a target peptide from the digest of the input protein database, or an annotated or generated decoy.

Note that columns with scores heavily depend on the chosen search engines and rescoring tools and are better looked up in the documentation of the underlying tool.

#### MSstats-processed mzTab

If MSstats was enabled, the pipeline additionally exports an mzTab file where the quantities are replaced with the normalized and imputed ones from
MSstats.

### MultiQC and pMultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/<ALIGNER>/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.

</details>

All the QC results for proteomics are currently generated by the [pMultiQC](https://github.com/bigbio/pmultiqc) library, a plugin of the popular visualization tool [MultiQC](http://multiqc.info). MultiQC is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

Results generated by pMultiQC collate pipeline QC from identifications and quantities throughout the pipeline. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use pMultiQC reports in general, see <https://github.com/bigbio/pmultiqc>.
