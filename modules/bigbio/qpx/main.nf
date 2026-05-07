process QPX_EXPORT {
    tag "qpx_export"
    label 'process_medium'
    label 'error_retry'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/qpx:1.0.2--pyhdfd78af_1'
        : 'biocontainers/qpx:1.0.2--pyhdfd78af_1'}"

    input:
    path(diann_report)
    path(pg_matrix)
    path(sdrf)
    path(diann_log)
    val(project_accession)

    output:
    path "qpx_output/" , emit: qpx_dataset
    path "*.h5mu"      , emit: mudata
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args ?: ''
    def prefix  = project_accession ?: 'diann'
    def pg_arg  = pg_matrix ? "--pg-matrix-path ${pg_matrix}" : ''
    def log_arg = diann_log ? "--diann-log ${diann_log}" : ''
    def acc_arg = project_accession ? "--project-accession ${project_accession}" : ''
    def qvalue  = params.matrix_qvalue ?: 0.05
    """
    set -o pipefail
    qpxc convert diann \\
        --report-path ${diann_report} \\
        --sdrf-file ${sdrf} \\
        ${pg_arg} \\
        ${log_arg} \\
        ${acc_arg} \\
        --output-folder qpx_output \\
        --output-prefix ${prefix} \\
        --qvalue-threshold ${qvalue} \\
        --standardized-intensities \\
        --duckdb-threads ${task.cpus} \\
        --duckdb-max-memory ${task.memory ? task.memory.toGiga() : 4}GB \\
        --compression zstd \\
        ${args}

    python - <<'PY'
from qpx.dataset import Dataset
from qpx.mudata import build_mudata

ds = Dataset("qpx_output")
mdata = build_mudata(ds)
mdata.write("${prefix}.h5mu")
ds.close()
print(f"MuData: {mdata.n_obs} obs x {mdata.n_vars} vars -> ${prefix}.h5mu")
PY

cat <<-END_VERSIONS > versions.yml
"${task.process}":
    qpx: \$(qpxc --version 2>&1 | sed 's/^qpx //')
    mudata: \$(python -c 'import mudata; print(mudata.__version__)')
END_VERSIONS
    """

    stub:
    def prefix = project_accession ?: 'diann'
    """
    mkdir -p qpx_output
    touch qpx_output/stub.parquet
    touch ${prefix}.h5mu

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qpx: stub
        mudata: stub
    END_VERSIONS
    """
}
