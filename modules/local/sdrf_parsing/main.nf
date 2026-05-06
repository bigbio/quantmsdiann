process SDRF_PARSING {
    tag "$sdrf.name"
    label 'process_tiny'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sdrf-pipelines:0.1.3--pyhdfd78af_0' :
        'biocontainers/sdrf-pipelines:0.1.3--pyhdfd78af_0' }"

    input:
    path sdrf

    output:
    path "diann_design.tsv"  , emit: ch_expdesign
    path "diann_config.cfg"  , emit: ch_diann_cfg
    path "*.log"             , emit: log
    path "versions.yml"      , emit: versions

    script:
    def args = task.ext.args ?: ''
    def mod_loc_flag = (params.enable_mod_localization && params.mod_localization) ?
        "--mod_localization '${params.mod_localization}'" : ''
    def diann_version_flag = params.diann_version ? "--diann_version '${params.diann_version}'" : ''

    """
    set -o pipefail
    parse_sdrf convert-diann \\
        -s ${sdrf} \\
        ${mod_loc_flag} \\
        ${diann_version_flag} \\
        $args \\
        2>&1 | tee ${sdrf.baseName}_parsing.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sdrf-pipelines: \$(parse_sdrf --version 2>/dev/null | awk -F ' ' '{print \$2}')
    END_VERSIONS
    """
}
