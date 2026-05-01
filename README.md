# bigbio/quantmsdiann

[![Open in GitHub Codespaces](https://img.shields.io/badge/Open_In_GitHub_Codespaces-black?labelColor=grey&logo=github)](https://github.com/codespaces/new/bigbio/quantmsdiann)
[![GitHub Actions CI Status](https://github.com/bigbio/quantmsdiann/actions/workflows/nf-test.yml/badge.svg)](https://github.com/bigbio/quantmsdiann/actions/workflows/nf-test.yml)
[![GitHub Actions Linting Status](https://github.com/bigbio/quantmsdiann/actions/workflows/linting.yml/badge.svg)](https://github.com/bigbio/quantmsdiann/actions/workflows/linting.yml)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.10.4-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-4.0.2-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/4.0.2)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/bigbio/quantmsdiann)

## Introduction

**bigbio/quantmsdiann** is a bioinformatics pipeline that ...

<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/community/brand/workflow-schematics#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))2. Present QC for raw reads ([`MultiQC`](http://multiqc.info/))

<<<<<<< HEAD
<p align="center">
  <img src="docs/images/quantmsdiann_workflow.svg" alt="quantmsdiann workflow" width="800">
</p>

The pipeline takes [SDRF](https://github.com/bigbio/proteomics-metadata-standard) metadata and mass spectrometry data files (`.raw`, `.mzML`, `.d`, `.dia`) as input and performs:

1. **Input validation** — SDRF parsing and validation via [sdrf-pipelines](https://github.com/bigbio/sdrf-pipelines)
2. **File preparation** — RAW to mzML conversion ([ThermoRawFileParser](https://github.com/compomics/ThermoRawFileParser)), indexing
3. **In-silico spectral library generation** — deep learning-based prediction, or use a user-provided library (`--speclib`)
4. **Preliminary analysis** — per-file calibration and mass accuracy estimation (parallelized)
5. **Empirical library assembly** — consensus library from preliminary results with RT profiling
6. **Individual analysis** — per-file search with the empirical library (parallelized)
7. **Final quantification** — protein/peptide/gene group matrices with cross-run normalization
8. **MSstats conversion** — DIA-NN report to [MSstats](https://msstats.org/)-compatible format
9. **Quality control** — interactive QC report via [pmultiqc](https://github.com/bigbio/pmultiqc)

## Supported DIA-NN Versions

| Version         | Profile        | Container                                  | Key features                                   |
| --------------- | -------------- | ------------------------------------------ | ---------------------------------------------- |
| 1.8.1 (default) | `diann_v1_8_1` | `docker.io/biocontainers/diann:v1.8.1_cv1` | Core DIA analysis, TSV output                  |
| 2.1.0           | `diann_v2_1_0` | `ghcr.io/bigbio/diann:2.1.0`               | Native .raw support, Parquet output            |
| 2.2.0           | `diann_v2_2_0` | `ghcr.io/bigbio/diann:2.2.0`               | Speed optimizations (up to 1.6x on HPC)        |
| 2.3.2           | `diann_v2_3_2` | `ghcr.io/bigbio/diann:2.3.2`               | DDA support (beta), InfinDIA, up to 9 var mods |

Switch versions with e.g. `-profile diann_v2_2_0,docker`. See the [DIA-NN Version Selection](docs/usage.md#dia-nn-version-selection) guide and [full parameter reference](docs/parameters.md) for details.

## Quick start
=======
## Usage
>>>>>>> fe9e018 (Template update for nf-core/tools version 4.0.2)

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/get_started/environment_setup/overview) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/get_started/run-your-first-pipeline) with `-profile test` before running the workflow on actual data.

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate):

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).

-->

Now, you can run the pipeline using:

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

```bash
nextflow run bigbio/quantmsdiann \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/running/run-pipelines#using-parameter-files).

## Credits

bigbio/quantmsdiann was originally written by Yasset Perez-Riverol.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](docs/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use bigbio/quantmsdiann for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
