process INDIVIDUAL_ANALYSIS {
    tag "$ms_file.baseName"
    label 'process_high'
    label 'diann'
    label 'error_retry'

    // DIA-NN's native Thermo .raw reader fails on symlinked files (Thermo SDK limitation).
    // Use 'copy' when .raw files are passed directly to DIA-NN (DIA-NN >= 2.1.0 without TRFP conversion).
    stageInMode { VersionUtils.isNativeRawMode(params) ? 'copy' : 'symlink' }

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://containers.biocontainers.pro/s3/SingImgsRepo/diann/v1.8.1_cv1/diann_v1.8.1_cv1.img' :
        'docker.io/biocontainers/diann:v1.8.1_cv1' }"

    input:
    tuple val(meta), path(ms_file), path(fasta), path(library)
    path(diann_config)

    output:
    path "*.quant", emit: diann_quant
    path "*_final_diann.log", emit: log
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // Strip flags managed by the pipeline from extra_args to prevent silent conflicts.
    // Blocked flags are defined centrally in lib/BlockedFlags.groovy — edit there, not here.
    args = BlockedFlags.strip('INDIVIDUAL_ANALYSIS', args, log)

    // Warn about flags that override pipeline-computed calibration values (not blocked, but may change behaviour)
    ['--individual-windows', '--individual-mass-acc'].each { flag ->
        if (args.contains(flag)) {
            log.warn "DIA-NN: '${flag}' overrides the mass accuracy / scan window values computed by the PRELIMINARY_ANALYSIS step. This may change pipeline behaviour."
        }
    }

    if (params.mass_acc_automatic || params.scan_window_automatic) {
        if (meta.mass_acc_ms2 != "0" && meta.mass_acc_ms2 != null) {
            mass_acc_ms2 = meta.mass_acc_ms2
            mass_acc_ms1 = meta.mass_acc_ms1
            scan_window  = meta.scan_window
        }
        else if (meta['precursormasstoleranceunit']?.toLowerCase()?.endsWith('ppm') && meta['fragmentmasstoleranceunit']?.toLowerCase()?.endsWith('ppm')) {
            mass_acc_ms2 = meta['fragmentmasstolerance']
            mass_acc_ms1 = meta['precursormasstolerance']
            scan_window  = params.scan_window
        }
        else {
            mass_acc_ms2 = params.mass_acc_ms2
            mass_acc_ms1 = params.mass_acc_ms1
            scan_window  = params.scan_window
        }
    } else {
        if (meta['precursormasstoleranceunit']?.toLowerCase()?.endsWith('ppm') && meta['fragmentmasstoleranceunit']?.toLowerCase()?.endsWith('ppm')) {
            mass_acc_ms1 = meta["precursormasstolerance"]
            mass_acc_ms2 = meta["fragmentmasstolerance"]
            scan_window  = params.scan_window
        }
        else if (meta.mass_acc_ms2 != "0" && meta.mass_acc_ms2 != null) {
            mass_acc_ms2 = meta.mass_acc_ms2
            mass_acc_ms1 = meta.mass_acc_ms1
            scan_window  = meta.scan_window
        }
        else {
            mass_acc_ms2 = params.mass_acc_ms2
            mass_acc_ms1 = params.mass_acc_ms1
            scan_window  = params.scan_window
        }
    }

    scoring_mode = params.scoring_mode == 'proteoforms' ? '--proteoforms' :
                         params.scoring_mode == 'peptidoforms' ? '--peptidoforms' : ''
    aa_eq = params.aa_eq ? '--aa-eq' : ''
    diann_tims_sum = params.tims_sum ? "--quant-tims-sum" : ""
    diann_im_window = params.im_window ? "--im-window $params.im_window" : ""
    diann_dda_flag = meta.acquisition_method == 'dda' ? "--dda" : ""

    // Flags removed in DIA-NN 2.3.x — only pass for older versions
    no_ifs_removal = VersionUtils.versionLessThan(params.diann_version, '2.3') ? "--no-ifs-removal" : ""
    no_main_report = VersionUtils.versionLessThan(params.diann_version, '2.3') ? "--no-main-report" : ""

    // Per-file scan ranges from SDRF (empty = no flag, DIA-NN auto-detects)
    min_pr_mz = meta['ms1minmz'] ? "--min-pr-mz ${meta['ms1minmz']}" : ""
    max_pr_mz = meta['ms1maxmz'] ? "--max-pr-mz ${meta['ms1maxmz']}" : ""
    min_fr_mz = meta['ms2minmz'] ? "--min-fr-mz ${meta['ms2minmz']}" : ""
    max_fr_mz = meta['ms2maxmz'] ? "--max-fr-mz ${meta['ms2maxmz']}" : ""

    """
    # Extract --var-mod, --fixed-mod, and --monitor-mod flags from diann_config.cfg
    mod_flags=\$(grep -oP '(--var-mod\\s+\\S+|--fixed-mod\\s+\\S+|--monitor-mod\\s+\\S+|--lib-fixed-mod\\s+\\S+|--original-mods|--channels\\s+.+)' ${diann_config} | tr '\\n' ' ')

    diann   --lib ${library} \\
            --f ${ms_file} \\
            --fasta ${fasta} \\
            --threads ${task.cpus} \\
            --verbose $params.debug_level \\
            --temp ./ \\
            --mass-acc ${mass_acc_ms2} \\
            --mass-acc-ms1 ${mass_acc_ms1} \\
            --window ${scan_window} \\
            ${no_ifs_removal} \\
            ${no_main_report} \\
            --relaxed-prot-inf \\
            --pg-level $params.pg_level \\
            ${min_pr_mz} \\
            ${max_pr_mz} \\
            ${min_fr_mz} \\
            ${max_fr_mz} \\
            ${scoring_mode} \\
            ${aa_eq} \\
            ${diann_tims_sum} \\
            ${diann_im_window} \\
            ${diann_dda_flag} \\
            \${mod_flags} \\
            $args \\
            2>&1 | tee ${ms_file.baseName}_final_diann.log

    if [ -f report.log.txt ]; then
        cp report.log.txt ${ms_file.baseName}_final_diann.log
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        DIA-NN: \$(diann 2>&1 | grep "DIA-NN" | grep -oP "\\d+\\.\\d+(\\.\\w+)*(\\.[\\d]+)?")
    END_VERSIONS
    """
}
