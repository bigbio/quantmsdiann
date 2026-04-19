# Building and Using DIA-NN Containers

quantmsdiann uses containerized DIA-NN for reproducibility across environments. This page explains how to obtain, build, and deploy DIA-NN containers for Docker and Singularity/Apptainer (HPC).

## Container availability

| DIA-NN Version | Registry | Image | Auth required |
| --- | --- | --- | --- |
| 1.8.1 | BioContainers | `biocontainers/diann:v1.8.1_cv1` | No |
| 2.1.0 | GHCR | `ghcr.io/bigbio/diann:2.1.0` | Yes |
| 2.2.0 | GHCR | `ghcr.io/bigbio/diann:2.2.0` | Yes |
| 2.3.2 | GHCR | `ghcr.io/bigbio/diann:2.3.2` | Yes |
| 2.5.0 | GHCR | `ghcr.io/bigbio/diann:2.5.0` | Yes |

DIA-NN 1.8.1 is the default version and uses a publicly available BioContainers image. DIA-NN 2.x images are hosted on GitHub Container Registry (`ghcr.io/bigbio`) and require authentication.

## Pulling pre-built containers

### Docker

```bash
# DIA-NN 1.8.1 (public, no auth)
docker pull biocontainers/diann:v1.8.1_cv1

# DIA-NN 2.x (requires GHCR token)
echo $GHCR_TOKEN | docker login ghcr.io -u $GHCR_USERNAME --password-stdin
docker pull ghcr.io/bigbio/diann:2.5.0
```

### Singularity / Apptainer

```bash
# DIA-NN 1.8.1 (public)
singularity pull docker://biocontainers/diann:v1.8.1_cv1

# DIA-NN 2.x (requires GHCR token)
export SINGULARITY_DOCKER_USERNAME=$GHCR_USERNAME
export SINGULARITY_DOCKER_PASSWORD=$GHCR_TOKEN
singularity pull docker://ghcr.io/bigbio/diann:2.5.0
```

To create a GHCR personal access token:

1. Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
2. Create a token with `read:packages` scope
3. Set `GHCR_USERNAME` to your GitHub username and `GHCR_TOKEN` to the token value

## Building containers yourself

If you don't have access to the `ghcr.io/bigbio` registry, you can build the containers from the [quantms-containers](https://github.com/bigbio/quantms-containers) repository.

### Option 1: Fork and use GitHub Actions (recommended)

1. Fork [bigbio/quantms-containers](https://github.com/bigbio/quantms-containers) to your GitHub account
2. The CI workflow runs automatically on push to `main` and builds all containers
3. Containers are pushed to your fork's GHCR: `ghcr.io/<your-username>/diann:2.5.0`
4. No code changes needed — the workflow uses `github.actor` for authentication

!!! note
    GitHub Packages created from forks may default to private. Check your [packages page](https://github.com/settings/packages) and adjust visibility if needed.

### Option 2: Build locally

```bash
# Clone the containers repo
git clone https://github.com/bigbio/quantms-containers.git
cd quantms-containers

# Build a specific version
docker buildx build --platform linux/amd64 -t diann:2.5.0 diann-2.5.0/

# Convert to Singularity SIF for HPC
singularity build diann-2.5.0.sif docker-daemon://diann:2.5.0
```

!!! important
    Always build with `--platform linux/amd64` — DIA-NN is an x86_64 binary. Building on Apple Silicon without this flag produces an ARM container that won't work.

### What's inside the containers

Each Dockerfile in [quantms-containers](https://github.com/bigbio/quantms-containers) follows the same pattern:

1. Base image: Ubuntu 22.04
2. Downloads the DIA-NN Academia Linux zip from the [official GitHub release](https://github.com/vdemichev/DiaNN/releases/tag/2.0)
3. Installs dependencies: `libgomp1` (OpenMP), locale support
4. Extracts to `/usr/diann-<version>/`
5. Creates a `diann` symlink and adds it to `PATH`

The `diann` command is available directly in the container without specifying a path.

## Deploying on HPC (Singularity/Apptainer)

### Step 1: Transfer SIF files to HPC

Place your `.sif` files in a shared location accessible by compute nodes:

```bash
# Example: shared storage on an HPC cluster
/shared/containers/diann-1.8.1.sif
/shared/containers/diann-2.5.0.sif
```

### Step 2: Create a custom Nextflow config

Create a config file that overrides the DIA-NN container path:

```groovy
// hpc_diann.config

singularity {
    enabled    = true
    autoMounts = true
    cacheDir   = '/shared/containers/cache'
}

process {
    withLabel: diann {
        container = '/shared/containers/diann-2.5.0.sif'
    }
}
```

!!! tip
    Use `withLabel: diann` (not `withName`) to override the container for **all** DIA-NN processes at once. All DIA-NN modules in quantmsdiann have the `diann` label.

### Step 3: Run the pipeline

```bash
nextflow run bigbio/quantmsdiann \
    -r 2.0.0 \
    -profile singularity \
    -c /path/to/hpc_diann.config \
    --input sdrf.tsv \
    --database db.fasta \
    --diann_version '2.5.0' \
    --outdir results
```

!!! warning "Important: `--diann_version` vs `-profile`"
    When using a **local SIF file**, set `--diann_version` manually to match the DIA-NN version in your container. The pipeline uses this value for version-dependent feature guards (e.g., DDA requires >= 2.3.2, InfinDIA requires >= 2.3.0).

    Do **not** combine a local SIF config with `-profile diann_v2_5_0` — the profile would override your local container path with the remote GHCR image.

### Step 4: Switch between versions

To use different DIA-NN versions for different runs, create a config per version or use a parameterized config:

```groovy
// hpc_diann_versions.config
params.diann_sif_path = '/shared/containers'

process {
    withLabel: diann {
        container = "${params.diann_sif_path}/diann-${params.diann_version}.sif"
    }
}
```

Then switch versions at runtime:

```bash
# Run with DIA-NN 2.3.2
nextflow run bigbio/quantmsdiann \
    -profile singularity \
    -c hpc_diann_versions.config \
    --diann_version '2.3.2' \
    --input sdrf.tsv --database db.fasta --outdir results

# Run with DIA-NN 2.5.0
nextflow run bigbio/quantmsdiann \
    -profile singularity \
    -c hpc_diann_versions.config \
    --diann_version '2.5.0' \
    --input sdrf.tsv --database db.fasta --outdir results
```

## SLURM cluster example

For SLURM-based HPC clusters (e.g., EBI Codon), see the bundled [pride_codon_slurm.config](https://github.com/bigbio/quantmsdiann/blob/main/conf/pride_codon_slurm.config) as a reference:

```bash
nextflow run bigbio/quantmsdiann \
    -profile singularity \
    -c conf/pride_codon_slurm.config \
    -c hpc_diann_versions.config \
    --input sdrf.tsv \
    --database db.fasta \
    --diann_version '2.5.0' \
    --outdir results
```

## Troubleshooting

| Problem | Solution |
| --- | --- |
| `FATAL: Unable to pull container` | Check GHCR authentication. Set `SINGULARITY_DOCKER_USERNAME` and `SINGULARITY_DOCKER_PASSWORD`. |
| `qemu-x86_64: Could not open '/lib64/ld-linux-x86-64.so.2'` | Container built for wrong architecture. Rebuild with `--platform linux/amd64`. |
| `diann: command not found` in container | Check the DIA-NN version path matches the Dockerfile. Run `docker run --rm diann:2.5.0 which diann` to verify. |
| Version guard errors (e.g., "DDA requires >= 2.3.2") | Set `--diann_version` to match your container. Don't rely on the default (1.8.1). |
| Container pulls from GHCR despite local SIF | Don't use `-profile diann_v2_X_0` with a custom config. Use `--diann_version` instead. |
