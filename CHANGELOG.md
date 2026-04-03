# bigbio/quantmsdiann: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
