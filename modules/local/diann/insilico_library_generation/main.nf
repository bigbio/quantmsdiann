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
    path(tuned_tokens)   // optional: fine-tuned tokenizer dict (pass [] when not used)
    path(tuned_rt_model) // optional: fine-tuned RT model (pass [] when not used)
    path(tuned_im_model) // optional: fine-tuned IM model (pass [] when not used)

    output:
    path "versions.yml", emit: versions
    path "*.predicted.speclib", emit: predict_speclib
    path "*.tsv", emit: speclib_tsv, optional: true
    path "silicolibrarygeneration.log", emit: log

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // Strip flags managed by the pipeline from extra_args to prevent silent conflicts.
    // Blocked flags are defined centrally in lib/BlockedFlags.groovy — edit there, not here.
    args = BlockedFlags.strip('INSILICO_LIBRARY_GENERATION', args, log)

    min_pr_mz = params.min_pr_mz ? "--min-pr-mz $params.min_pr_mz":""
    max_pr_mz = params.max_pr_mz ? "--max-pr-mz $params.max_pr_mz":""
    min_fr_mz = params.min_fr_mz ? "--min-fr-mz $params.min_fr_mz":""
    max_fr_mz = params.max_fr_mz ? "--max-fr-mz $params.max_fr_mz":""
    met_excision = params.met_excision ? "--met-excision" : ""
    scoring_mode = params.scoring_mode == 'proteoforms' ? '--proteoforms' :
                         params.scoring_mode == 'peptidoforms' ? '--peptidoforms' : ''
    aa_eq = params.aa_eq ? '--aa-eq' : ''
    diann_dda_flag = is_dda ? "--dda" : ""
    diann_light_models = params.light_models ? "--light-models" : ""
    // Fine-tuned model flags — only set when tuned model files are provided
    tuned_tokens_flag = tuned_tokens ? "--tokens ${tuned_tokens}" : ''
    tuned_rt_flag = tuned_rt_model ? "--rt-model ${tuned_rt_model}" : ''
    tuned_im_flag = tuned_im_model ? "--im-model ${tuned_im_model}" : ''
    infin_dia_flag = params.enable_infin_dia ? "--infin-dia" : ""
    pre_select_flag = (params.enable_infin_dia && params.pre_select) ? "--pre-select $params.pre_select" : ""

    """
    diann `cat ${diann_config}` \\
            --fasta ${fasta} \\
            --fasta-search \\
            --out silicolibrarygeneration.tsv \\
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
            --verbose $params.debug_level \\
            --gen-spec-lib \\
            ${scoring_mode} \\
            ${aa_eq} \\
            ${diann_light_models} \\
            ${tuned_tokens_flag} \\
            ${tuned_rt_flag} \\
            ${tuned_im_flag} \\
            ${infin_dia_flag} \\
            ${pre_select_flag} \\
            ${met_excision} \\
            ${diann_dda_flag} \\
            ${args} \\
            2>&1 | tee silicolibrarygeneration.log

    if [ -f silicolibrarygeneration.log.txt ]; then
        cp silicolibrarygeneration.log.txt silicolibrarygeneration.log
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        DIA-NN: \$(diann 2>&1 | grep "DIA-NN" | grep -oP "\\d+\\.\\d+(\\.\\w+)*(\\.[\\d]+)?")
    END_VERSIONS
    """
}
