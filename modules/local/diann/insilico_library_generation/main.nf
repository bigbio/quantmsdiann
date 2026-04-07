process INSILICO_LIBRARY_GENERATION {
    tag "$fasta.name"
    label 'process_medium'
    label 'diann'
    label 'error_retry'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://containers.biocontainers.pro/s3/SingImgsRepo/diann/v1.8.1_cv1/diann_v1.8.1_cv1.img' :
        'docker.io/biocontainers/diann:v1.8.1_cv1' }"

    input:
    path(fasta)
    path(diann_config)
    val(is_dda)

    output:
    path "versions.yml", emit: versions
    path "*.predicted.speclib", emit: predict_speclib
    path "*.tsv", emit: speclib_tsv, optional: true
    path "silicolibrarygeneration.log", emit: log

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // Strip flags that are managed by the pipeline to prevent silent conflicts
    def blocked = ['--use-quant', '--no-main-report', '--matrices', '--out',
         '--temp', '--threads', '--verbose', '--lib', '--f', '--fasta',
         '--fasta-search', '--predictor', '--gen-spec-lib',
         '--missed-cleavages', '--min-pep-len', '--max-pep-len',
         '--min-pr-charge', '--max-pr-charge', '--var-mods',
         '--min-pr-mz', '--max-pr-mz', '--min-fr-mz', '--max-fr-mz',
         '--met-excision', '--monitor-mod', '--dda', '--light-models',
         '--infin-dia', '--pre-select']
    // Sort by length descending so longer flags (e.g. --fasta-search) are matched before shorter prefixes (--fasta, --f)
    blocked.sort { a -> -a.length() }.each { flag ->
        def flagPattern = '(?<=^|\\s)' + java.util.regex.Pattern.quote(flag) + '(?=\\s|\$)(\\s+(?!-{1,2}[a-zA-Z])\\S+)*'
        if (args =~ flagPattern) {
            log.warn "DIA-NN: '${flag}' is managed by the pipeline for INSILICO_LIBRARY_GENERATION and will be stripped."
            args = args.replaceAll(flagPattern, '').trim()
        }
    }

    min_pr_mz = params.min_pr_mz ? "--min-pr-mz $params.min_pr_mz":""
    max_pr_mz = params.max_pr_mz ? "--max-pr-mz $params.max_pr_mz":""
    min_fr_mz = params.min_fr_mz ? "--min-fr-mz $params.min_fr_mz":""
    max_fr_mz = params.max_fr_mz ? "--max-fr-mz $params.max_fr_mz":""
    met_excision = params.met_excision ? "--met-excision" : ""
    diann_no_peptidoforms = params.diann_no_peptidoforms ? "--no-peptidoforms" : ""
    diann_dda_flag = is_dda ? "--dda" : ""
    diann_light_models = params.diann_light_models ? "--light-models" : ""
    infin_dia_flag = params.enable_infin_dia ? "--infin-dia" : ""
    pre_select_flag = (params.enable_infin_dia && params.diann_pre_select) ? "--pre-select $params.diann_pre_select" : ""

    """
    diann `cat ${diann_config}` \\
            --fasta ${fasta} \\
            --fasta-search \\
            ${min_pr_mz} \\
            ${max_pr_mz} \\
            ${min_fr_mz} \\
            ${max_fr_mz} \\
            --missed-cleavages $params.allowed_missed_cleavages \\
            --min-pep-len $params.min_peptide_length \\
            --max-pep-len $params.max_peptide_length \\
            --min-pr-charge $params.min_precursor_charge \\
            --max-pr-charge $params.max_precursor_charge \\
            --var-mods $params.max_mods \\
            --threads ${task.cpus} \\
            --predictor \\
            --verbose $params.diann_debug \\
            --gen-spec-lib \\
            ${diann_no_peptidoforms} \\
            ${diann_light_models} \\
            ${infin_dia_flag} \\
            ${pre_select_flag} \\
            ${met_excision} \\
            ${diann_dda_flag} \\
            ${args}

    cp *lib.log.txt silicolibrarygeneration.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        DIA-NN: \$(diann 2>&1 | grep "DIA-NN" | grep -oP "\\d+\\.\\d+(\\.\\w+)*(\\.[\\d]+)?")
    END_VERSIONS
    """
}
