process ASSEMBLE_EMPIRICAL_LIBRARY {
    tag "$meta.experiment_id"
    label 'process_low'
    label 'diann'
    label 'error_retry'

    // DIA-NN's native Thermo .raw reader fails on symlinked files (Thermo SDK limitation).
    // Use 'copy' when .raw files are passed directly to DIA-NN (DIA-NN >= 2.1.0 without TRFP conversion).
    stageInMode { VersionUtils.isNativeRawMode(params) ? 'copy' : 'symlink' }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://containers.biocontainers.pro/s3/SingImgsRepo/diann/v1.8.1_cv1/diann_v1.8.1_cv1.img' :
        'docker.io/biocontainers/diann:v1.8.1_cv1' }"

    input:
    // In this step the real files are passed, and not the names
    path(ms_files)
    val(meta)
    path("quant/*")
    path(lib)
    path(diann_config)

    output:
    path "empirical_library.*", emit: empirical_library
    path "assemble_empirical_library.log", emit: log
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // Strip flags managed by the pipeline from extra_args to prevent silent conflicts.
    // Blocked flags are defined centrally in lib/BlockedFlags.groovy — edit there, not here.
    args = BlockedFlags.strip('ASSEMBLE_EMPIRICAL_LIBRARY', args, log)

    if (params.mass_acc_automatic) {
        mass_acc = '--individual-mass-acc'
    } else if (meta['precursormasstoleranceunit']?.toLowerCase()?.endsWith('ppm') && meta['fragmentmasstoleranceunit']?.toLowerCase()?.endsWith('ppm')){
        mass_acc = "--mass-acc ${meta['fragmentmasstolerance']} --mass-acc-ms1 ${meta['precursormasstolerance']}"
    } else {
        mass_acc = '--individual-mass-acc'
    }
    scan_window = params.scan_window_automatic ? '--individual-windows' : "--window $params.scan_window"
    scoring_mode = params.scoring_mode == 'proteoforms' ? '--proteoforms' :
                         params.scoring_mode == 'peptidoforms' ? '--peptidoforms' : ''
    aa_eq = params.aa_eq ? '--aa-eq' : ''
    diann_tims_sum = params.tims_sum ? "--quant-tims-sum" : ""
    diann_im_window = params.im_window ? "--im-window $params.im_window" : ""
    diann_dda_flag = meta.acquisition_method == 'dda' ? "--dda" : ""

    diann_channel_run_norm = params.channel_run_norm ? "--channel-run-norm" : ""
    diann_channel_spec_norm = params.channel_spec_norm ? "--channel-spec-norm" : ""

    """
    # Precursor Tolerance value was: ${meta['precursormasstolerance']}
    # Fragment Tolerance value was: ${meta['fragmentmasstolerance']}
    # Precursor Tolerance unit was: ${meta['precursormasstoleranceunit']}
    # Fragment Tolerance unit was: ${meta['fragmentmasstoleranceunit']}

    ls -lcth

    # Extract --var-mod, --fixed-mod, and --monitor-mod flags from diann_config.cfg
    mod_flags=\$(grep -oP '(--var-mod\\s+\\S+|--fixed-mod\\s+\\S+|--monitor-mod\\s+\\S+|--lib-fixed-mod\\s+\\S+|--original-mods|--channels\\s+.+)' ${diann_config} | tr '\\n' ' ')

    diann   --f ${(ms_files as List).join(' --f ')} \\
            --lib ${lib} \\
            --threads ${task.cpus} \\
            --out-lib empirical_library \\
            --verbose $params.debug_level \\
            --rt-profiling \\
            --temp ./quant/ \\
            --use-quant \\
            ${mass_acc} \\
            ${scan_window} \\
            --gen-spec-lib \\
            ${scoring_mode} \\
            ${aa_eq} \\
            ${diann_tims_sum} \\
            ${diann_im_window} \\
            ${diann_dda_flag} \\
            ${diann_channel_run_norm} \\
            ${diann_channel_spec_norm} \\
            \${mod_flags} \\
            $args \\
            2>&1 | tee assemble_empirical_library.log

    if [ -f report.log.txt ]; then
        cp report.log.txt assemble_empirical_library.log
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        DIA-NN: \$(diann 2>&1 | grep "DIA-NN" | grep -oP "\\d+\\.\\d+(\\.\\w+)*(\\.[\\d]+)?")
    END_VERSIONS
    """
}
