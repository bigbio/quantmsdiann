process WIFF_CONVERT {
    tag "$meta.id"
    label 'process_high'

    container "quay.io/wiffconverter:0.10"

    input:
    tuple val(meta), path(wiff_files)

    output:
    tuple val(meta), path("*.mzML"), emit: mzML
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def wiff_main = wiff_files.find { it.name.endsWith('.wiff') }
    
    """
    export HOME=/tmp

    convert \\
        --input ${wiff_main} \\
        --output ${prefix}.mzML

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wiffconverter: 0.10
    END_VERSIONS
    """
}