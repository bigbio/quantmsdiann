# Installation

## Requirements

- [Nextflow](https://www.nextflow.io/) (>= 23.04.0)
- Container: [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/)

## Install Nextflow

```bash
curl -s https://get.nextflow.io | bash
mv nextflow ~/bin/
nextflow -version
```

## Container Profiles

```bash
# Docker (local/cloud)
nextflow run bigbio/quantmsdiann -profile docker

# Singularity (HPC)
nextflow run bigbio/quantmsdiann -profile singularity
```

## Cloud Execution

```bash
# AWS Batch
nextflow run bigbio/quantmsdiann -profile docker \
    --input s3://bucket/samplesheet.csv \
    --outdir s3://bucket/results/

# Google Cloud
nextflow run bigbio/quantmsdiann -profile docker \
    --input gs://bucket/samplesheet.csv \
    --outdir gs://bucket/results/
```

## Test Run

```bash
# Quick test (~10 min)
nextflow run bigbio/quantmsdiann -profile test,docker --outdir test_results/

# Test with DIA-NN 2.2.0
nextflow run bigbio/quantmsdiann \
    -profile test,docker \
    -c conf/diann_versions/v2_2_0.config \
    --outdir test_results/
```

## DIA-NN Versions

quantmsdiann supports multiple DIA-NN versions:

| DIA-NN Version | Config                              | Notes                    |
| -------------- | ----------------------------------- | ------------------------ |
| 1.8.1          | `conf/diann_versions/v1_8_1.config` | Legacy, widely validated |
| 2.1.0          | `conf/diann_versions/v2_1_0.config` | Improved algorithms      |
| 2.2.0          | `conf/diann_versions/v2_2_0.config` | Latest, best performance |

```bash
# Specify version
nextflow run bigbio/quantmsdiann \
    -profile docker \
    -c conf/diann_versions/v2_2_0.config \
    --input samplesheet.csv \
    --database uniprot.fasta \
    --outdir results/
```
