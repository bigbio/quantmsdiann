process THERMORAWFILEPARSER {
    tag "${meta.id}"
    label 'process_low'
    label 'process_single'
    label 'error_retry'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/thermorawfileparser:2.0.0.dev--h9ee0642_0' :
        'biocontainers/thermorawfileparser:2.0.0.dev--h9ee0642_0' }"

    input:
    tuple val(meta), path(raw)

    output:
    tuple val(meta), path("*.{mzML,mzML.gz,mgf,mgf.gz,parquet,parquet.gz}"), emit: spectra
    tuple val("${task.process}"), val('thermorawfileparser'), eval("thermorawfileparser --version"), emit: versions_thermorawfileparser, topic: versions
    path "*.log", emit: log

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // Detect existing format options in any supported syntax: -f=2, -f 2, --format=2,
    // or --format 2.
    def hasFormatArg = (args =~ /(^|\s)(-f(=|\s)\d+|--format(=|\s)\d+)/).find()
    // Default to indexed mzML format (-f=2) if not specified in args
    def formatArg = hasFormatArg ? '' : '-f=2'
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = args.contains("--format 0") || args.contains("-f 0")
        ? "mgf"
        : args.contains("--format 1") || args.contains("-f 1")
            ? "mzML"
            : args.contains("--format 2") || args.contains("-f 2")
                ? "mzML"
                : args.contains("--format 3") || args.contains("-f 3")
                    ? "parquet"
                    : "mzML"
    suffix = args.contains("--gzip") ? "${suffix}.gz" : "${suffix}"

    """
    thermorawfileparser \\
        -i='${raw}' \\
        ${formatArg} ${args} \\
        -o=./ 2>&1 | tee '${prefix}_conversion.log'
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = args.contains("--format 0") || args.contains("-f 0")
        ? "mgf"
        : args.contains("--format 1") || args.contains("-f 1")
            ? "mzML"
            : args.contains("--format 2") || args.contains("-f 2")
                ? "mzML"
                : args.contains("--format 3") || args.contains("-f 3")
                    ? "parquet"
                    : "mzML"
    suffix = args.contains("--gzip") ? "${suffix}.gz" : "${suffix}"

    """
    touch '${prefix}.${suffix}'
    touch '${prefix}_conversion.log'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ThermoRawFileParser: \$(thermorawfileparser --version)
    END_VERSIONS
    """
}
