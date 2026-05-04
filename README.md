# quantmsdiann

[![GitHub Actions CI Status](https://github.com/bigbio/quantmsdiann/actions/workflows/ci.yml/badge.svg)](https://github.com/bigbio/quantmsdiann/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/bigbio/quantmsdiann/actions/workflows/linting.yml/badge.svg)](https://github.com/bigbio/quantmsdiann/actions/workflows/linting.yml)
[![Cite with Zenodo](https://zenodo.org/badge/DOI/10.5281/zenodo.19437128.svg)](https://doi.org/10.5281/zenodo.19437128)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.10.4-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-4.0.2-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/4.0.2)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

## Introduction

**quantmsdiann** is a [bigbio](https://github.com/bigbio) bioinformatics pipeline, built following [nf-core](https://nf-co.re/) guidelines, for quantitative mass spectrometry analysis using [DIA-NN](https://github.com/vdemichev/DiaNN). It supports **Data-Independent Acquisition (DIA)** workflows including label-free, plexDIA (mTRAQ, SILAC, Dimethyl), phosphoproteomics with site localization, and Bruker timsTOF/PASEF data.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a portable manner. It uses Docker/Singularity containers making results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process, making it easy to maintain and update software dependencies.

## Pipeline summary

<p align="center">
  <img src="docs/images/quantmsdiann_workflow.svg" alt="quantmsdiann workflow" width="800">
</p>

The pipeline takes [SDRF](https://github.com/bigbio/proteomics-metadata-standard) metadata (must use the `.sdrf.tsv` extension) and mass spectrometry data files (`.raw`, `.mzML`, `.d`, `.dia`) as input and performs:

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

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set up Nextflow.

**Run with test data:**

```bash
nextflow run bigbio/quantmsdiann -profile test_dia,docker --outdir results
```

**Run with your own data:**

```bash
nextflow run bigbio/quantmsdiann \
    --input 'experiment.sdrf.tsv' \
    --database 'proteins.fasta' \
    --outdir './results' \
    -profile docker
```

**Run with a specific DIA-NN version:**

```bash
nextflow run bigbio/quantmsdiann \
    --input 'experiment.sdrf.tsv' \
    --database 'proteins.fasta' \
    --outdir './results' \
    -profile docker,diann_v2_2_0
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), not for defining parameters.

## Documentation

- [Usage](docs/usage.md) — How to run the pipeline, input formats, optional outputs, and custom configuration
- [Parameters](docs/parameters.md) — Complete reference of all pipeline parameters organised by category
- [Output](docs/output.md) — Description of all output files produced by the pipeline

## Credits

quantmsdiann is developed and maintained by:

- [Yasset Perez-Riverol](https://github.com/ypriverol) (EMBL-EBI)
- [Dai Chengxin](https://github.com/daichengxin) (Beijing Proteome Research Center)
- [Julianus Pfeuffer](https://github.com/jpfeuffer) (Freie Universitat Berlin)
- [Vadim Demichev](https://github.com/vdemichev) (Charite Universitaetsmedizin Berlin)
- [Qi-Xuan Yue](https://github.com/yueqixuan) (Chongqing University of Posts and Telecommunications)

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](docs/CONTRIBUTING.md).

## Citation

If you use quantmsdiann in your research, please cite:

> Dai et al. "quantms: a cloud-based pipeline for quantitative proteomics" (2024). DOI: [10.5281/zenodo.19437128](https://doi.org/10.5281/zenodo.19437128)

An extensive list of references for the tools used by the pipeline can be found in the [CITATIONS.md](CITATIONS.md) file.

## License

[MIT](LICENSE)
