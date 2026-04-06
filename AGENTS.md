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

**quantmsdiann** is a [bigbio](https://github.com/bigbio) bioinformatics pipeline, built following [nf-core](https://nf-co.re/) guidelines, for **DIA-NN-based quantitative mass spectrometry**. It is a standalone pipeline focused exclusively on **Data-Independent Acquisition (DIA)** workflows using the DIA-NN search engine.

**This pipeline does NOT support DDA, TMT, iTRAQ, LFQ-DDA, or any non-DIA workflows.** Those are handled by the parent `quantms` pipeline.

**Key Features:**

- Built with Nextflow DSL2
- DIA-NN for peptide/protein identification and quantification
- Supports DIA-NN v1.8.1, v2.1.0, and v2.2.0 (latest)
- QuantUMS quantification method (DIA-NN >= 1.9.2)
- Parquet-native output with decoy reporting (DIA-NN >= 2.0)
- MSstats-compatible output generation (via quantms-utils conversion, no MSstats analysis)
- Quality control with pmultiqc
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
- **DIA-NN**: Primary search engine (versions 1.8.1 through 2.2.0)

### Key Configuration Files

- `nextflow.config` - Main pipeline configuration
- `nextflow_schema.json` - Parameter schema (auto-generated)
- `nf-test.config` - Testing configuration
- `.nf-core.yml` - nf-core compliance settings
- `modules.json` - Module dependencies
- `.pre-commit-config.yaml` - Pre-commit hooks

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
│   ├── tests/                 # Test profile configs (DIA only)
│   └── diann_versions/        # DIA-NN version-override configs for merge matrix
├── tests/                     # nf-test test cases
└── assets/                    # Pipeline assets and schemas
```

---

## DIA-NN Workflow

The pipeline executes the following steps:

1. **SDRF Validation & Parsing** - Validates input SDRF and extracts metadata
2. **File Preparation** - Converts RAW/mzML/.d/.dia files (ThermoRawFileParser, tdf2mzml)
3. **Generate Config** - Creates DIA-NN config from enzyme/modifications (`quantmsutilsc dianncfg`)
4. **In-Silico Library Generation** - Predicts spectral library from FASTA (or uses provided library)
5. **Preliminary Analysis** - Per-file calibration and mass accuracy determination
6. **Assemble Empirical Library** - Builds consensus library from preliminary results using .quant files
7. **Individual Analysis** - Per-file search with empirical library (optional, for large datasets)
8. **Final Quantification** - Summary quantification with protein/peptide/gene matrices
9. **MSstats Format Conversion** - Converts DIA-NN report to MSstats-compatible CSV (`quantmsutilsc diann2msstats`)
10. **pmultiqc** - Quality control reporting

### DIA-NN Version-Specific Features

| Feature                                     | Min Version | Parameter                    |
| ------------------------------------------- | ----------- | ---------------------------- |
| Core workflow, library-free, .quant caching | 1.8.1       | (default)                    |
| QuantUMS quantification                     | 1.9.2       | `--quantums true`            |
| Parquet output format                       | 2.0         | (automatic in 2.0+)          |
| Decoy reporting                             | 2.0         | `--diann_report_decoys true` |
| Native .raw on Linux                        | 2.1.0       | (automatic)                  |

---

## Validation Workflow

### 1. Pre-commit Hooks (MANDATORY)

**Installation:**

```bash
pip install pre-commit
pre-commit install  # Install git hooks (one-time setup)
```

**Run before EVERY commit:**

```bash
pre-commit run --all-files
```

**Configured Hooks** (`.pre-commit-config.yaml`):

1. **Prettier** - Formats code consistently across multiple file types
2. **trailing-whitespace** - Removes trailing whitespace (preserves markdown linebreaks)
3. **end-of-file-fixer** - Ensures files end with a single newline

**Auto-fix in CI:**
If you forget to run pre-commit locally, comment on your PR:

```
@nf-core-bot fix linting
```

### 2. Pipeline Linting (RECOMMENDED)

```bash
nf-core pipelines lint
# For master branch PRs:
nf-core pipelines lint --release
```

### 3. Schema Validation (REQUIRED for parameter changes)

```bash
nf-core pipelines schema build
```

---

## Testing Strategy

### 3-Tier CI/CD Strategy

1. **Every PR / push to dev**: Test all features against **latest** DIA-NN (2.2.0) + test **1.8.1** for features it supports.
2. **Merge dev → master**: Run the **full version × feature matrix** — every DIA-NN version against every feature it introduced.
3. **ci.yml** (fast gate): Only 1.8.1 public container tests, no auth needed.

### Test Profiles (DIA only)

| Profile             | Feature Tested          | Default Container            | Min DIA-NN |
| ------------------- | ----------------------- | ---------------------------- | ---------- |
| `test_dia`          | Core workflow           | biocontainers 1.8.1 (public) | 1.8.1      |
| `test_dia_dotd`     | Bruker .d format        | biocontainers 1.8.1 (public) | 1.8.1      |
| `test_dia_quantums` | QuantUMS quantification | ghcr.io/bigbio/diann:2.2.0   | 1.9.2      |
| `test_dia_parquet`  | Parquet output + decoys | ghcr.io/bigbio/diann:2.2.0   | 2.0        |
| `test_latest_dia`   | Core on latest DIA-NN   | ghcr.io/bigbio/diann:2.2.0   | latest     |
| `test_dia_2_2_0`    | DIA-NN 2.2.0 compat     | ghcr.io/bigbio/diann:2.2.0   | 2.2.0      |
| `test_full_dia`     | Full-size dataset       | biocontainers 1.8.1 (public) | 1.8.1      |

### Version Override Profiles (for merge matrix)

These apply on top of test profiles to override the DIA-NN container version:

| Profile        | Container                        | Auth |
| -------------- | -------------------------------- | ---- |
| `diann_v1_8_1` | `biocontainers/diann:v1.8.1_cv1` | none |
| `diann_v2_1_0` | `ghcr.io/bigbio/diann:2.1.0`     | GHCR |
| `diann_v2_2_0` | `ghcr.io/bigbio/diann:2.2.0`     | GHCR |

### CI Workflows

| Workflow            | Trigger                 | What it runs                                         |
| ------------------- | ----------------------- | ---------------------------------------------------- |
| **ci.yml**          | Every PR (fast gate)    | `test_dia`, `test_dia_dotd` (1.8.1, Docker)          |
| **extended_ci.yml** | Every PR / push to dev  | 1.8.1 defaults + all features on 2.2.0 + Singularity |
| **merge_ci.yml**    | PR to master / releases | Full version × feature matrix (10 combinations)      |
| **linting.yml**     | All PRs, releases       | Pre-commit hooks + `nf-core pipelines lint`          |
| **branch.yml**      | PRs to master           | Only allows PRs from `dev` branch                    |

### When to Run Tests Locally

**No testing required:**

- README, CHANGELOG, docs/ updates
- Minor config tweaks (labels, descriptions)
- Comment additions

**Targeted testing required:**

| Change Area                     | Test Profile         | Command                                                                 |
| ------------------------------- | -------------------- | ----------------------------------------------------------------------- |
| Core DIA-NN modules             | `test_dia`           | `nextflow run . -profile test_dia,docker --outdir results`              |
| Bruker .d support               | `test_dia_dotd`      | `nextflow run . -profile test_dia_dotd,docker --outdir results`         |
| QuantUMS / final_quantification | `test_dia_quantums`  | `nextflow run . -profile test_dia_quantums,docker --outdir results`     |
| Parquet output / diann_msstats  | `test_dia_parquet`   | `nextflow run . -profile test_dia_parquet,docker --outdir results`      |
| Cross-version compat            | Use version override | `nextflow run . -profile test_dia,diann_v2_2_0,docker --outdir results` |

**Comprehensive testing (before PR):**

```bash
nf-test test --profile debug,test,docker --verbose
```

### Container Authentication

Tests using `ghcr.io/bigbio/diann:*` containers require GHCR authentication (DIA-NN has an academic-only license):

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u $GHCR_USERNAME --password-stdin
```

In CI, the `GHCR_USERNAME` and `GHCR_TOKEN` secrets are configured in the repository.

---

## Development Conventions

### Branch Strategy

- **Target branch**: `dev` (NOT master)
- **Master branch**: Release-ready code only
- **PR process**: Fork -> feature branch -> PR to `dev`

### Naming Conventions

#### Channel Names

```groovy
ch_output_from_<process_name>     // Initial output from a process
ch_<previous_process>_for_<next_process>  // Intermediate channels
```

#### Process/Module Names

- Use lowercase with underscores: `final_quantification`, `preliminary_analysis`
- Follow nf-core conventions for consistency

### Resource Labels

Defined in `conf/base.config`:

| Label              | CPU | Memory | Time | Use Case              |
| ------------------ | --- | ------ | ---- | --------------------- |
| `process_single`   | 1   | 6 GB   | 4h   | Single-threaded tools |
| `process_tiny`     | 1   | 1 GB   | 1h   | Minimal processing    |
| `process_very_low` | 2   | 12 GB  | 4h   | Light parallelism     |
| `process_low`      | 4   | 36 GB  | 8h   | Moderate workload     |
| `process_medium`   | 8   | 72 GB  | 16h  | Standard processing   |
| `process_high`     | 12  | 108 GB | 20h  | Heavy computation     |

### DIA-NN Module Labels

All DIA-NN process modules use the `diann` label for container selection:

```groovy
process DIANN_FINAL_QUANTIFICATION {
    label 'process_high'
    label 'diann'
    // ...
}
```

The `diann` label is what version-override profiles target to switch containers.

### Adding a New DIA-NN Feature

1. **Identify minimum DIA-NN version** that supports the feature
2. **Modify the relevant module** in `modules/local/diann/`
3. **Add parameter** to `nextflow.config` with sensible default
4. **Update schema**: `nf-core pipelines schema build`
5. **Create or update test profile** in `conf/tests/` with the feature enabled
6. **Add to CI matrix** in `extended_ci.yml` (latest) and `merge_ci.yml` (version matrix)
7. **Update documentation**: `docs/usage.md`, `docs/output.md`

### Code Style

- **Indentation**: 4 spaces (enforced by Prettier)
- **Line length**: Aim for <120 characters
- **Comments**: Use `//` for single-line, `/* */` for multi-line
- **Strings**: Use single quotes `'text'` unless interpolation needed `"$var"`
- **Groovy closures**: Follow Nextflow DSL2 patterns

---

## Troubleshooting

### Pre-commit Issues

**Problem**: Pre-commit hook fails with formatting issues

**Solution**: The files were auto-fixed. Stage and commit again:

```bash
git add .
git commit -m "your message"
```

### Testing Issues

**Problem**: Test fails with "Process exceeded memory limit"

**Solution**: Ensure you're using a test profile with resource limits:

```bash
nextflow run . -profile test_dia,docker --outdir results
```

**Problem**: GHCR container pull fails

**Solution**: Feature test profiles require GHCR authentication:

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u $GHCR_USERNAME --password-stdin
```

For local testing without GHCR access, use `test_dia` or `test_dia_dotd` (public containers).

**Problem**: Snapshot test fails after intentional output changes

**Solution**: Update snapshots:

```bash
nf-test test --profile debug,test,docker --update-snapshot
```

### Nextflow Issues

**Problem**: "Nextflow version is too old"

**Solution**:

```bash
nextflow self-update
# Or install specific version
export NXF_VER=25.04.0
```

**Problem**: "Process terminated with exit code 137"

**Solution**: Out of memory. Either:

1. Use test profile: `-profile test_dia,docker`
2. Increase Docker memory limit in Docker Desktop settings

**Problem**: Process error

**Solution**:

1. Check `.nextflow.log` for details
2. Check work directory: `cat work/<hash>/.command.err`
3. Rerun with debug: `nextflow run . -profile debug,test_dia,docker --outdir results`

---

## Quick Reference

### Essential Commands

```bash
# Pre-commit (MANDATORY before commit)
pre-commit run --all-files

# Lint pipeline
nf-core pipelines lint

# Update schema after parameter changes
nf-core pipelines schema build

# Run core DIA test (public container, no auth)
nextflow run . -profile test_dia,docker --outdir results

# Run QuantUMS test (requires GHCR auth)
nextflow run . -profile test_dia_quantums,docker --outdir results

# Run with specific DIA-NN version override
nextflow run . -profile test_dia,diann_v2_2_0,docker --outdir results

# Run nf-test suite
nf-test test --profile debug,test,docker --verbose

# Resume pipeline
nextflow run . -profile test_dia,docker --outdir results -resume

# Clean work directory
nextflow clean -f
```

### File Locations

- **Main config**: `nextflow.config`
- **Schema**: `nextflow_schema.json`
- **Pre-commit config**: `.pre-commit-config.yaml`
- **nf-test config**: `nf-test.config`
- **Test configs**: `conf/tests/*.config`
- **Version overrides**: `conf/diann_versions/*.config`
- **Module configs**: `conf/modules/modules.config`
- **Base resources**: `conf/base.config`
- **Main workflow**: `workflows/quantmsdiann.nf`
- **DIA workflow**: `workflows/dia.nf`
- **DIA-NN modules**: `modules/local/diann/*/main.nf`
- **Entry point**: `main.nf`

---

**Last Updated**: April 2, 2026
**Pipeline Version**: 1.0.0
**Minimum Nextflow**: 25.04.0
