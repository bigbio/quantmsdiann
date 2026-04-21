process FINE_TUNE_MODELS {
    tag "fine_tune"
    label 'process_medium'
    label 'diann'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://containers.biocontainers.pro/s3/SingImgsRepo/diann/v1.8.1_cv1/diann_v1.8.1_cv1.img' :
        'docker.io/biocontainers/diann:v1.8.1_cv1' }"

    input:
    path(tune_lib)
    path(fasta)
    path(diann_config)

    output:
    path "*.dict.txt", emit: tokens
    path "*.{tuned_rt,rt.d0}.pt", emit: rt_model, optional: true
    path "*.{tuned_im,im.d0}.pt", emit: im_model, optional: true
    path "*.{tuned_fr,fr.d0}.pt", emit: fr_model, optional: true
    path "fine_tune.log", emit: log
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // Strip flags managed by the pipeline from extra_args to prevent silent conflicts.
    // Blocked flags are defined centrally in lib/BlockedFlags.groovy — edit there, not here.
    args = BlockedFlags.strip('FINE_TUNE_MODELS', args, log)

    tune_fr = params.tune_fr ? '--tune-fr' : ''
    tune_lr = params.tune_lr ? "--tune-lr ${params.tune_lr}" : ''

    // Extract mod flags from diann_config.cfg so DIA-NN recognises modifications in the library
    """
    mod_flags=\$(grep -oP '(--var-mod\\s+\\S+|--fixed-mod\\s+\\S+|--monitor-mod\\s+\\S+|--lib-fixed-mod\\s+\\S+|--original-mods|--channels\\s+.+)' ${diann_config} | tr '\\n' ' ')

    diann   --tune-lib ${tune_lib} \\
            --tune-rt \\
            --tune-im \\
            ${tune_fr} \\
            ${tune_lr} \\
            --fasta ${fasta} \\
            --threads ${task.cpus} \\
            --verbose $params.debug_level \\
            \${mod_flags} \\
            $args \\
            2>&1 | tee fine_tune.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        DIA-NN: \$(diann 2>&1 | grep "DIA-NN" | grep -oP "\\d+\\.\\d+(\\.\\w+)*(\\.[\\d]+)?")
    END_VERSIONS
    """
}
