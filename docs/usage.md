# bigbio/quantmsdiann: Usage

## Introduction

quantmsdiann is a Nextflow pipeline for DIA-NN-based quantitative mass spectrometry analysis.

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run bigbio/quantmsdiann \
    --input 'experiment.sdrf.tsv' \
    --database 'proteins.fasta' \
    --outdir './results' \
    -profile docker
```

The input file must be in [Sample-to-data-relationship format (SDRF)](https://pubs.acs.org/doi/abs/10.1021/acs.jproteome.0c00376) and can have `.sdrf`, `.tsv`, or `.csv` file extensions.

### Supported file formats

The pipeline supports the following mass spectrometry data file formats:

- **`.raw`** - Thermo RAW files (automatically converted to mzML)
- **`.mzML`** - Open standard mzML files
- **`.d`** - Bruker timsTOF files (optionally converted to mzML when `--convert_dotd` is set)
- **`.dia`** - DIA-NN native binary format (passed through without conversion)

Compressed variants are supported for `.raw`, `.mzML`, and `.d` formats: `.gz`, `.tar`, `.tar.gz`, `.zip`.

### Pipeline settings via params file

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`:

```bash
nextflow run bigbio/quantmsdiann -profile docker -params-file params.yaml
```

```yaml
input: "./experiment.sdrf.tsv"
database: "./proteins.fasta"
outdir: "./results"
```

> [!WARNING]
> Do not use `-c <file>` to specify parameters. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) or module arguments.

### Reproducibility

Specify the pipeline version when running on your data:

```bash
nextflow run bigbio/quantmsdiann -r 1.8.0 -profile docker --input sdrf.tsv --database db.fasta --outdir results
```

## Core Nextflow arguments

### `-profile`

Use this parameter to choose a configuration profile:

- `docker` - Run with Docker containers
- `singularity` - Run with Singularity containers
- `podman` - Run with Podman containers
- `apptainer` - Run with Apptainer containers

Multiple profiles can be loaded: `-profile test_dia,docker`

### `-resume`

Resume from cached results:

```bash
nextflow run bigbio/quantmsdiann -profile test_dia,docker --outdir results -resume
```

## Test profiles

```bash
# Quick DIA test
nextflow run . -profile test_dia,docker --outdir results

# DIA with Bruker .d files
nextflow run . -profile test_dia_dotd,docker --outdir results

# Latest DIA-NN version (2.1.0)
nextflow run . -profile test_latest_dia,docker --outdir results
```

## Custom configuration

### Resource requests

Each step in the pipeline has default resource requirements. If a job exits with error code `137` or `143` (exceeded resources), it will automatically resubmit with higher requests (2x, then 3x original).

To customize resources for a specific process:

```nextflow
process {
    withName: 'BIGBIO_QUANTMSDIANN:QUANTMSDIANN:DIA:FINAL_QUANTIFICATION' {
        memory = 100.GB
    }
}
```

Save this to a file and pass via `-c custom.config`.

## Running in the background

Use `screen`, `tmux`, or the Nextflow `-bg` flag to run the pipeline in the background:

```bash
nextflow run bigbio/quantmsdiann -profile docker --input sdrf.tsv --database db.fasta --outdir results -bg
```

## Nextflow memory requirements

Add the following to your environment to limit Java memory:

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
