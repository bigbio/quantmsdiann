process DIANN_MSSTATS {
    tag "diann_msstats"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/quantms-utils:0.0.30--pyhdfd78af_0' :
        'biocontainers/quantms-utils:0.0.30--pyhdfd78af_0' }"

    input:
    path(report)
    path(exp_design)

    output:
    path "*msstats_in.csv", emit: out_msstats
    path "*.log", emit: log
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    // Precursor q-value: explicit param wins, else auto by diann_version (<2.5 -> 0.01, >=2.5 -> 0.05)
    def precursor_qvalue = VersionUtils.resolvePrecursorQvalue(params)
    """
    set -o pipefail
    quantmsutilsc diann2msstats \\
        --report ${report} \\
        --exp_design ${exp_design} \\
        --qvalue_threshold ${precursor_qvalue} \\
        $args \\
        2>&1 | tee convert_report.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quantms-utils: \$(pip show quantms-utils | grep "Version" | awk -F ': ' '{print \$2}')
    END_VERSIONS
    """
}
