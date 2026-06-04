process WIFF_CONVERT {
    tag "$meta.id"
    label 'process_single'
    label 'error_retry'

    // GHCR-hosted container; pulling may require `docker login ghcr.io` for some
    // network/firewall setups, but the image itself is publicly accessible.
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://ghcr.io/bigbio/wiffconverter-sif:0.10' :
        'ghcr.io/bigbio/wiffconverter:0.10' }"

    input:
    tuple val(meta), path(wiff_files)

    output:
    tuple val(meta), path("*.mzML"), emit: mzML
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def wiff_main = wiff_files.find { it.name.endsWith('.wiff') }
    def tool_version = task.container ? task.container.split(':').last() : '0.10'

    """
    export HOME=/tmp

    convert \\
        --input ${wiff_main} \\
        --output ${prefix}.mzML

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wiffconverter: ${tool_version}
    END_VERSIONS
    """

    stub:
    def stub_prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${stub_prefix}.mzML

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wiffconverter: 0.10
    END_VERSIONS
    """
}
