process INDIVIDUAL_ANALYSIS {
    tag "$ms_file.baseName"
    label 'process_high'
    label 'diann'

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
    // Strip flags that are managed by the pipeline to prevent silent conflicts
    def blocked = ['--use-quant', '--gen-spec-lib', '--out-lib', '--matrices', '--out', '--rt-profiling',
         '--temp', '--threads', '--verbose', '--lib', '--f', '--fasta',
         '--mass-acc', '--mass-acc-ms1', '--window',
         '--no-ifs-removal', '--no-main-report', '--relaxed-prot-inf', '--pg-level',
         '--min-pr-mz', '--max-pr-mz', '--min-fr-mz', '--max-fr-mz',
         '--monitor-mod', '--var-mod', '--fixed-mod']
    // Sort by length descending so longer flags (e.g. --mass-acc-ms1) are matched before shorter prefixes (--mass-acc)
    blocked.sort { a -> -a.length() }.each { flag ->
        def flagPattern = '(?<=^|\\s)' + java.util.regex.Pattern.quote(flag) + '(?=\\s|\$)(\\s+(?!-{1,2}[a-zA-Z])\\S+)*'
        if (args =~ flagPattern) {
            log.warn "DIA-NN: '${flag}' is managed by the pipeline for INDIVIDUAL_ANALYSIS and will be stripped."
            args = args.replaceAll(flagPattern, '').trim()
        }
    }

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
        else if (meta['fragmentmasstolerance']) {
            mass_acc_ms2 = meta['fragmentmasstolerance']
            mass_acc_ms1 = meta['precursormasstolerance']
            scan_window  = params.scan_window
        }
        else {
            mass_acc_ms2 = params.mass_acc_ms2
            mass_acc_ms1 = params.mass_acc_ms1
            scan_window  = params.scan_window
        }
    } else if (meta['precursormasstoleranceunit']?.toLowerCase()?.endsWith('ppm') && meta['fragmentmasstoleranceunit']?.toLowerCase()?.endsWith('ppm')) {
        mass_acc_ms1 = meta["precursormasstolerance"]
        mass_acc_ms2 = meta["fragmentmasstolerance"]
    } else {
        if (meta.mass_acc_ms2 != "0" && meta.mass_acc_ms2 != null) {
            mass_acc_ms2 = meta.mass_acc_ms2
            mass_acc_ms1 = meta.mass_acc_ms1
            scan_window  = meta.scan_window
        } else if (meta['fragmentmasstolerance']) {
            mass_acc_ms2 = meta['fragmentmasstolerance']
            mass_acc_ms1 = meta['precursormasstolerance']
            scan_window  = params.scan_window
        } else {
            mass_acc_ms2 = params.mass_acc_ms2
            mass_acc_ms1 = params.mass_acc_ms1
            scan_window  = params.scan_window
        }
    }

    diann_no_peptidoforms = params.diann_no_peptidoforms ? "--no-peptidoforms" : ""
    diann_tims_sum = params.diann_tims_sum ? "--quant-tims-sum" : ""
    diann_im_window = params.diann_im_window ? "--im-window $params.diann_im_window" : ""

    // Per-file scan ranges from SDRF (empty = no flag, DIA-NN auto-detects)
    min_pr_mz = meta['ms1minmz'] ? "--min-pr-mz ${meta['ms1minmz']}" : ""
    max_pr_mz = meta['ms1maxmz'] ? "--max-pr-mz ${meta['ms1maxmz']}" : ""
    min_fr_mz = meta['ms2minmz'] ? "--min-fr-mz ${meta['ms2minmz']}" : ""
    max_fr_mz = meta['ms2maxmz'] ? "--max-fr-mz ${meta['ms2maxmz']}" : ""

    """
    # Extract --var-mod, --fixed-mod, and --monitor-mod flags from diann_config.cfg
    mod_flags=\$(cat ${diann_config} | grep -oP '(--var-mod\\s+\\S+|--fixed-mod\\s+\\S+|--monitor-mod\\s+\\S+)' | tr '\\n' ' ')

    diann   --lib ${library} \\
            --f ${ms_file} \\
            --fasta ${fasta} \\
            --threads ${task.cpus} \\
            --verbose $params.diann_debug \\
            --temp ./ \\
            --mass-acc ${mass_acc_ms2} \\
            --mass-acc-ms1 ${mass_acc_ms1} \\
            --window ${scan_window} \\
            --no-ifs-removal \\
            --no-main-report \\
            --relaxed-prot-inf \\
            --pg-level $params.pg_level \\
            ${min_pr_mz} \\
            ${max_pr_mz} \\
            ${min_fr_mz} \\
            ${max_fr_mz} \\
            ${diann_no_peptidoforms} \\
            ${diann_tims_sum} \\
            ${diann_im_window} \\
            \${mod_flags} \\
            $args

    cp report.log.txt ${ms_file.baseName}_final_diann.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        DIA-NN: \$(diann 2>&1 | grep "DIA-NN" | grep -oP "\\d+\\.\\d+(\\.\\w+)*(\\.[\\d]+)?")
    END_VERSIONS
    """
}
