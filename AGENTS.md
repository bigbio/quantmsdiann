# AI Agent Guidelines for quantmsdiann Development

This document provides comprehensive guidance for AI agents working with the **quantmsdiann** bioinformatics pipeline. These guidelines ensure code quality, maintainability, and compliance with project standards.

## Critical: Mandatory Validation Before ANY Commit

**ALWAYS run pre-commit hooks before committing ANY changes:**

```bash
pre-commit run --all-files
```

This is **non-negotiable**. All code must pass formatting and style checks before being committed.

---

## Project Overview

**quantmsdiann** is an nf-core bioinformatics best-practice analysis pipeline for **DIA-NN-based quantitative mass spectrometry**. It is a standalone pipeline focused exclusively on **Data-Independent Acquisition (DIA)** workflows using the DIA-NN search engine.

**Key Features:**

- Built with Nextflow DSL2
- DIA-NN for peptide/protein identification and quantification
- Supports DIA-NN v1.8.1 and v2.1.0
- MSstats-compatible output generation (via quantms-utils conversion)
- Quality control with pMultiQC
- Complies with nf-core standards

**Repository:** https://github.com/bigbio/quantmsdiann

---

## Technology Stack

### Core Technologies

- **Nextflow**: >=25.04.0 (DSL2 syntax)
- **nf-schema plugin**: 2.5.1 (parameter validation)
- **nf-test**: Testing framework (config: `nf-test.config`)
- **nf-core tools**: Pipeline standards and linting
- **Containers**: Docker/Singularity/Apptainer/Podman (Conda deprecated)

### Project Structure

```
quantmsdiann/
├── main.nf                    # Pipeline entry point
├── workflows/
│   ├── quantmsdiann.nf        # Main workflow orchestrator
│   └── dia.nf                 # DIA-NN analysis workflow
├── subworkflows/local/        # Reusable subworkflows
│   ├── input_check/           # SDRF validation
│   ├── file_preparation/      # Format conversion
│   └── create_input_channel/  # SDRF metadata parsing
├── modules/local/
│   ├── diann/                 # DIA-NN modules (7 steps)
│   │   ├── generate_cfg/
│   │   ├── insilico_library_generation/
│   │   ├── preliminary_analysis/
│   │   ├── assemble_empirical_library/
│   │   ├── individual_analysis/
│   │   ├── final_quantification/
│   │   └── diann_msstats/
│   ├── openms/                # mzML indexing, peak picking
│   ├── pmultiqc/              # QC reporting
│   ├── sdrf_parsing/          # SDRF parsing
│   ├── samplesheet_check/     # Input validation
│   └── utils/                 # tdf2mzml, decompress, mzml stats
├── conf/
│   ├── base.config            # Resource definitions
│   ├── modules/               # Module-specific configs
│   └── tests/                 # Test profile configs (DIA only)
├── tests/                     # nf-test test cases
└── assets/                    # Pipeline assets and schemas
```

---

## DIA-NN Workflow

The pipeline executes the following steps:

1. **SDRF Validation & Parsing** - Validates input SDRF and extracts metadata
2. **File Preparation** - Converts RAW/mzML/.d/.dia files
3. **Generate Config** - Creates DIA-NN config from enzyme/modifications
4. **In-Silico Library Generation** - Predicts spectral library from FASTA (or uses provided library)
5. **Preliminary Analysis** - Per-file calibration and mass accuracy determination
6. **Assemble Empirical Library** - Builds consensus library from preliminary results
7. **Individual Analysis** - Per-file search with empirical library
8. **Final Quantification** - Summary quantification with matrix output
9. **MSstats Format Conversion** - Converts DIA-NN report to MSstats-compatible CSV
10. **pMultiQC** - Quality control reporting

---

## Testing Strategy

### Test Profiles (DIA only)

| Change Area        | Test Profile        | Container                       | Command                                                               |
| ------------------ | ------------------- | ------------------------------- | --------------------------------------------------------------------- |
| DIA workflow       | `test_dia`          | default (1.8.1)                 | `nextflow run . -profile test_dia,docker --outdir results`            |
| DIA with Bruker    | `test_dia_dotd`     | default (1.8.1)                 | `nextflow run . -profile test_dia_dotd,docker --outdir results`       |
| QuantUMS quant     | `test_dia_quantums` | ghcr.io/bigbio/diann:2.1.0     | `nextflow run . -profile test_dia_quantums,docker --outdir results`   |
| Parquet / decoys   | `test_dia_parquet`  | ghcr.io/bigbio/diann:2.1.0     | `nextflow run . -profile test_dia_parquet,docker --outdir results`    |
| DIA-NN 2.2.0       | `test_dia_2_2_0`    | ghcr.io/bigbio/diann:2.2.0     | `nextflow run . -profile test_dia_2_2_0,docker --outdir results`      |
| Latest DIA-NN      | `test_latest_dia`   | ghcr.io/bigbio/diann:2.1.0     | `nextflow run . -profile test_latest_dia,docker --outdir results`     |
| Full DIA dataset   | `test_full_dia`     | default (1.8.1)                 | `nextflow run . -profile test_full_dia,docker --outdir results`       |

### CI Test Matrix

- **ci.yml**: `test_dia`, `test_dia_dotd` (Docker)
- **extended_ci.yml**: `test_dia`, `test_dia_dotd`, `test_dia_quantums`, `test_dia_parquet`, `test_dia_2_2_0`, `test_latest_dia` (Docker + Singularity)

---

## Development Conventions

### Branch Strategy

- **Target branch**: `dev` (NOT master)
- **Master branch**: Release-ready code only
- **PR process**: Fork -> feature branch -> PR to `dev`

### Essential Commands

```bash
# Pre-commit (MANDATORY before commit)
pre-commit run --all-files

# Lint pipeline
nf-core pipelines lint

# Update schema after parameter changes
nf-core pipelines schema build

# Run DIA test
nextflow run . -profile test_dia,docker --outdir results

# Run nf-test suite
nf-test test --profile debug,test,docker --verbose

# Resume pipeline
nextflow run . -profile test_dia,docker --outdir results -resume
```

---

**Last Updated**: March 17, 2026
**Pipeline Version**: 1.8.0dev
**Minimum Nextflow**: 25.04.0
