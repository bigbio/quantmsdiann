process PRIDEPY_DOWNLOAD {
    tag "${meta.id}"
    label 'process_low'
    label 'process_long'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/pridepy:0.0.14--pyhdfd78af_0'
        : 'biocontainers/pridepy:0.0.14--pyhdfd78af_0'}"

    input:
    val(meta)

    output:
    tuple val(meta), path("*.{raw,mzML,mzML.gz,mgf,d.tar,d.tar.gz,d.zip,dia,wiff,wiff.scan}"), emit: spectra,   optional: true
    tuple val(meta), path("*-checksum.tsv"),                                                   emit: checksums, optional: true
    path "versions.yml",                                                                       emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    pridepy ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pridepy: \$(python -c "from importlib.metadata import version; print(version('pridepy'))" || echo "unknown")
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def checksum_touch = args.contains('--checksum-check') ? "touch \"${meta.id}-checksum.tsv\"" : ''
    """
    touch "${meta.id}.raw"
    ${checksum_touch}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pridepy: 0.0.14
    END_VERSIONS
    """
}
