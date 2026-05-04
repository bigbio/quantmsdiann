process SAMPLESHEET_CHECK {

    tag "$input_file"
    label 'process_tiny'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/quantms-utils:0.0.29--pyhdfd78af_0' :
        'biocontainers/quantms-utils:0.0.29--pyhdfd78af_0' }"

    input:
    path input_file

    output:
    path "*.log", emit: log
    path "*.sdrf.tsv", includeInputs: true, emit: checked_file
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def string_use_ols_cache_only = params.use_ols_cache_only == true ? "--use_ols_cache_only" : ""

    """
    set -o pipefail

    # --input is schema-validated to end in .sdrf.tsv (nextflow_schema.json
    # pattern ^\\S+\\.sdrf\\.tsv\$), so the staged file is already in the
    # required format — pass it through to the checker as-is.
    quantmsutilsc checksamplesheet --exp_design "${input_file}" \\
    --minimal \\
    ${string_use_ols_cache_only} \\
    $args \\
    2>&1 | tee input_check.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quantms-utils: \$(pip show quantms-utils | grep "Version" | awk -F ': ' '{print \$2}')
    END_VERSIONS
    """
}
