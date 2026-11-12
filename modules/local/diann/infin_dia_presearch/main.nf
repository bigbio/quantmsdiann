process INFIN_DIA_PRESEARCH {
    tag "$fasta.name"
    label 'process_high'
    label 'diann'
    label 'error_retry'

    // DIA-NN cannot read a symlinked Thermo .raw; only the MS files are copied, in the script.
    stageInMode 'symlink'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://ghcr.io/bigbio/diann-public-sif:1.8.1' :
        'ghcr.io/bigbio/diann-public:1.8.1' }"

    input:
    path(ms_files)
    path(fasta)
    path(diann_config)
    val(is_dda)
    path(diann_license)  // optional: DIA-NN Enterprise license key (pass [] when not used)

    output:
    path "infindia_library.parquet", emit: library
    path "infindia_presearch.log", emit: log
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // Strip flags managed by the pipeline from extra_args to prevent silent conflicts.
    // Blocked flags are defined centrally in lib/BlockedFlags.groovy — edit there, not here.
    args = BlockedFlags.strip('INFIN_DIA_PRESEARCH', args, log)

    min_pr_mz = params.min_pr_mz ? "--min-pr-mz $params.min_pr_mz":""
    max_pr_mz = params.max_pr_mz ? "--max-pr-mz $params.max_pr_mz":""
    min_fr_mz = params.min_fr_mz ? "--min-fr-mz $params.min_fr_mz":""
    max_fr_mz = params.max_fr_mz ? "--max-fr-mz $params.max_fr_mz":""
    met_excision = params.met_excision ? "--met-excision" : ""
    scoring_mode = params.scoring_mode == 'proteoforms' ? '--proteoforms' :
                         params.scoring_mode == 'peptidoforms' ? '--peptidoforms' : ''
    aa_eq = params.aa_eq ? '--aa-eq' : ''
    strip_unknown_mods = params.strip_unknown_mods ? "--strip-unknown-mods" : ""
    diann_dda_flag = is_dda ? "--dda" : ""
    diann_light_models = params.light_models ? "--light-models" : ""
    pre_select_flag = params.pre_select ? "--pre-select $params.pre_select" : ""
    // DIA-NN Enterprise license; falls back to a key next to the binary when no path is provided
    license_arg = diann_license ? "--license ${diann_license}" : ""

    stage_ms_files = VersionUtils.isNativeRawMode(params) ?
        (ms_files as List).collect { f ->
            "if [ -L '${f}' ]; then cp -rL '${f}' '${f}.__staged' && rm -f '${f}' && mv '${f}.__staged' '${f}'; fi"
        }.join('\n    ') : ':'

    // Params defaults come before diann_config.cfg so that SDRF values there (ppm tolerances, m/z
    // ranges) take precedence: DIA-NN keeps the last value. --pre-search needs fixed mass accuracies.
    // No --fasta-search/--predictor: these would predict the whole FASTA before the pre-search.
    """
    ${stage_ms_files}
    diann   --mass-acc $params.mass_acc_ms2 \\
            --mass-acc-ms1 $params.mass_acc_ms1 \\
            ${min_pr_mz} \\
            ${max_pr_mz} \\
            ${min_fr_mz} \\
            ${max_fr_mz} \\
            `cat ${diann_config}` \\
            --f ${(ms_files as List).join(' --f ')} \\
            --fasta ${fasta} \\
            --pre-search \\
            ${pre_select_flag} \\
            --gen-spec-lib \\
            --out-lib infindia_library.parquet \\
            --missed-cleavages $params.allowed_missed_cleavages \\
            --min-pep-len $params.min_peptide_length \\
            --max-pep-len $params.max_peptide_length \\
            --min-pr-charge $params.min_precursor_charge \\
            --max-pr-charge $params.max_precursor_charge \\
            --var-mods $params.max_mods \\
            --threads ${task.cpus} \\
            --verbose $params.debug_level \\
            ${scoring_mode} \\
            ${aa_eq} \\
            ${strip_unknown_mods} \\
            ${license_arg} \\
            ${diann_light_models} \\
            ${met_excision} \\
            ${diann_dda_flag} \\
            ${args} \\
            2>&1 | tee infindia_presearch.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        DIA-NN: \$(diann 2>&1 | grep "DIA-NN" | grep -oP "\\d+\\.\\d+(\\.\\w+)*(\\.[\\d]+)?")
    END_VERSIONS
    """
}
