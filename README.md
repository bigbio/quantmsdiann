# quantmsdiann

[![GitHub Actions CI Status](https://github.com/bigbio/quantmsdiann/actions/workflows/ci.yml/badge.svg)](https://github.com/bigbio/quantmsdiann/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/bigbio/quantmsdiann/actions/workflows/linting.yml/badge.svg)](https://github.com/bigbio/quantmsdiann/actions/workflows/linting.yml)
[![Cite with Zenodo](https://zenodo.org/badge/DOI/10.5281/zenodo.15573386.svg)](https://doi.org/10.5281/zenodo.15573386)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.04.0-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-3.5.2-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/3.5.2)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

**quantmsdiann** is an [nf-core](https://nf-co.re/) bioinformatics pipeline for **Data-Independent Acquisition (DIA)** quantitative mass spectrometry analysis using [DIA-NN](https://github.com/vdemichev/DiaNN).

## Pipeline Overview

The pipeline takes SDRF metadata and mass spectrometry data files as input, performs DIA-NN-based identification and quantification, and produces protein/peptide quantification matrices, MSstats-compatible output, and QC reports.

### Workflow Diagram

<p align="center">
  <img src="docs/images/quantmsdiann_workflow.svg" alt="quantmsdiann workflow" width="520">
</p>

### Supported Input Formats

| Format  | Description                 | Handling                                |
| ------- | --------------------------- | --------------------------------------- |
| `.raw`  | Thermo RAW files            | Converted to mzML (ThermoRawFileParser) |
| `.mzML` | Open standard mzML          | Optionally re-indexed                   |
| `.d`    | Bruker timsTOF directories  | Native or converted to mzML             |
| `.dia`  | DIA-NN native binary format | Passed through without conversion       |

Compressed formats (`.gz`, `.tar`, `.tar.gz`, `.zip`) are supported for `.raw`, `.mzML`, and `.d`.

## Quick Start

```bash
nextflow run bigbio/quantmsdiann \
    --input 'experiment.sdrf.tsv' \
    --database 'proteins.fasta' \
    --outdir './results' \
    -profile docker
```

## Key Output Files

| File                                      | Description                         |
| ----------------------------------------- | ----------------------------------- |
| `quant_tables/diann_report.tsv`           | Main DIA-NN peptide/protein report  |
| `quant_tables/diann_report.pg_matrix.tsv` | Protein group quantification matrix |
| `quant_tables/diann_report.pr_matrix.tsv` | Precursor quantification matrix     |
| `quant_tables/diann_report.gg_matrix.tsv` | Gene group quantification matrix    |
| `quant_tables/out_msstats_in.csv`         | MSstats-compatible quantification   |
| `pmultiqc/`                               | Interactive QC HTML report          |

## Test Profiles

```bash
# Quick DIA test
nextflow run . -profile test_dia,docker --outdir results

# DIA with Bruker .d files
nextflow run . -profile test_dia_dotd,docker --outdir results

# Latest DIA-NN (2.2.0)
nextflow run . -profile test_latest_dia,docker --outdir results
```

## Documentation

- [Usage](docs/usage.md) - How to run the pipeline
- [Output](docs/output.md) - Description of output files

## Credits

quantmsdiann is developed and maintained by:

- [Yasset Perez-Riverol](https://github.com/ypriverol) (EMBL-EBI)
- [Dai Chengxin](https://github.com/daichengxin) (Beijing Proteome Research Center)
- [Julianus Pfeuffer](https://github.com/jpfeuffer) (Freie Universitat Berlin)
- [Vadim Demichev](https://github.com/vdemichev) (Charite Universitaetsmedizin Berlin)
- [Qi-Xuan Yue](https://github.com/yueqixuan)

## License

[MIT](LICENSE)

## Citation

If you use quantmsdiann in your research, please cite:

> Dai et al. "quantms: a cloud-based pipeline for quantitative proteomics" (2024). DOI: [10.5281/zenodo.15573386](https://doi.org/10.5281/zenodo.15573386)
