process WIFF_CONVERT {
    tag "$meta.id"
    label 'process_single'

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
}
