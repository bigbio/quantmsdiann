# Input Files

## SDRF (Recommended)

The required input is an [SDRF](https://github.com/bigbio/sdrf-pipelines) file describing your experiment:

```bash
nextflow run bigbio/quantmsdiann \
    -profile docker \
    --input experiment.sdrf.tsv \
    --database uniprot.fasta \
    --outdir results/
```

The SDRF file contains sample metadata, raw file paths, and experimental conditions in a standardized format. quantmsdiann currently supports SDRF inputs only when they use the `.sdrf.tsv` extension.

## Supported Raw Formats

| Format     | Extension | Instrument          |
| ---------- | --------- | ------------------- |
| Thermo RAW | `.raw`    | Orbitrap, Exploris  |
| Bruker .d  | `.d`      | timsTOF             |
| mzML       | `.mzML`   | Any (pre-converted) |

!!! info "Automatic conversion"
Thermo `.raw` files are automatically converted to mzML via ThermoRawFileParser. Bruker `.d` directories are converted via tdf2mzml. Pre-converted `.mzML` files are used directly.

## FASTA Database

Standard UniProt FASTA protein sequences. DIA-NN generates decoy sequences automatically if needed.

```bash
# Download human proteome
wget https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000005640/UP000005640_9606.fasta.gz
gunzip UP000005640_9606.fasta.gz
```

## Spectral Library (Optional)

For library-based DIA analysis, provide a spectral library:

```bash
nextflow run bigbio/quantmsdiann \
    -profile docker \
    --input experiment.sdrf.tsv \
    --database uniprot.fasta \
    --spectral_library library.tsv \
    --outdir results/
```

If no library is provided, DIA-NN runs in **library-free mode** using in-silico predicted spectra.
