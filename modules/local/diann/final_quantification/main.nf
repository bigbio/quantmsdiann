process FINAL_QUANTIFICATION {
    tag "$meta.experiment_id"
    label 'process_high'
    label 'diann'
    label 'error_retry'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://containers.biocontainers.pro/s3/SingImgsRepo/diann/v1.8.1_cv1/diann_v1.8.1_cv1.img' :
        'docker.io/biocontainers/diann:v1.8.1_cv1' }"

    input:
    // Note that the files are passed as names and not paths, this prevents them from being staged
    // in the directory
    val(ms_files)
    val(meta)
    path(empirical_library)
    // The quant path is passed, and diann will use the files in the quant directory instead
    // of the ones passed in ms_files.
    path("quant/")
    path(fasta)
    path(diann_config)

    output:
    // DIA-NN < 1.9 produces TSV; >= 1.9 produces parquet (ignores .tsv in --out)
    // Both are optional since only one format will be produced per version
    path "diann_report.parquet", emit: main_report_parquet, optional: true
    path "diann_report.tsv", emit: main_report_tsv, optional: true
    path "diann_report.manifest.txt", emit: report_manifest, optional: true
    path "diann_report.protein_description.tsv", emit: protein_description, optional: true
    path "diann_report.stats.tsv", emit: report_stats, optional: true
    path "diann_report.pr_matrix.tsv", emit: pr_matrix, optional: true
    path "diann_report.pg_matrix.tsv", emit: pg_matrix, optional: true
    path "diann_report.gg_matrix.tsv", emit: gg_matrix, optional: true
    path "diann_report.unique_genes_matrix.tsv", emit: unique_gene_matrix, optional: true
    path "diannsummary.log", emit: log

    // Different library files format are exported due to different DIA-NN versions
    path "empirical_library.tsv", emit: final_speclib, optional: true
    path "empirical_library.tsv.skyline.speclib", emit: skyline_speclib, optional: true
    path "*.site_report.parquet", emit: site_report, optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // Strip flags managed by the pipeline from extra_args to prevent silent conflicts.
    // Blocked flags are defined centrally in lib/BlockedFlags.groovy — edit there, not here.
    args = BlockedFlags.strip('FINAL_QUANTIFICATION', args, log)

    scan_window = params.scan_window_automatic ? "--individual-windows" : "--window $params.scan_window"
    species_genes = params.species_genes ? "--species-genes": ""
    no_norm = params.normalize ? "" : "--no-norm"
    report_decoys = params.report_decoys ? "--report-decoys": ""
    diann_export_xic = params.export_xic ? "--xic": ""
    // --direct-quant exists in DIA-NN >= 1.9.2 (QuantUMS counterpart); skip for older versions
    quantums = params.quantums ? "" : (VersionUtils.versionAtLeast(params.diann_version, '1.9.2') ? "--direct-quant" : "")
    quantums_train_runs = params.quantums_train_runs ? "--quant-train-runs $params.quantums_train_runs": ""
    quantums_sel_runs = params.quantums_sel_runs ? "--quant-sel-runs $params.quantums_sel_runs": ""
    quantums_params = params.quantums_params ? "--quant-params $params.quantums_params": ""
    scoring_mode = params.scoring_mode == 'proteoforms' ? '--proteoforms' :
                         params.scoring_mode == 'peptidoforms' ? '--peptidoforms' : ''
    aa_eq = params.aa_eq ? '--aa-eq' : ''
    diann_use_quant = params.use_quant ? "--use-quant" : ""
    diann_dda_flag = meta.acquisition_method == 'dda' ? "--dda" : ""
    diann_export_quant = params.export_quant ? "--export-quant" : ""
    diann_site_ms1_quant = params.site_ms1_quant ? "--site-ms1-quant" : ""
    diann_channel_run_norm = params.channel_run_norm ? "--channel-run-norm" : ""
    diann_channel_spec_norm = params.channel_spec_norm ? "--channel-spec-norm" : ""

    """
    # Notes: if .quant files are passed, mzml/.d files are not accessed, so the name needs to be passed but files
    # do not need to be present.

    # Extract --var-mod, --fixed-mod, and --monitor-mod flags from diann_config.cfg
    mod_flags=\$(grep -oP '(--var-mod\\s+\\S+|--fixed-mod\\s+\\S+|--monitor-mod\\s+\\S+|--lib-fixed-mod\\s+\\S+|--original-mods|--channels\\s+.+)' ${diann_config} | tr '\\n' ' ')

    diann   --lib ${empirical_library} \\
            --fasta ${fasta} \\
            --f ${(ms_files as List).join(' --f ')} \\
            --threads ${task.cpus} \\
            --verbose $params.debug_level \\
            --temp ./quant/ \\
            --relaxed-prot-inf \\
            --pg-level $params.pg_level \\
            ${species_genes} \\
            ${no_norm} \\
            --matrices \\
            --out diann_report.tsv \\
            --qvalue $params.precursor_qvalue \\
            --matrix-qvalue $params.matrix_qvalue \\
            --matrix-spec-q $params.matrix_spec_q \\
            ${report_decoys} \\
            ${diann_export_xic} \\
            ${quantums} \\
            ${quantums_train_runs} \\
            ${quantums_sel_runs} \\
            ${quantums_params} \\
            ${scoring_mode} \\
            ${aa_eq} \\
            ${diann_use_quant} \\
            ${diann_dda_flag} \\
            ${diann_export_quant} \\
            ${diann_site_ms1_quant} \\
            ${diann_channel_run_norm} \\
            ${diann_channel_spec_norm} \\
            \${mod_flags} \\
            $args \\
            2>&1 | tee diannsummary.log

    if [ -f diann_report.log.txt ]; then
        cp diann_report.log.txt diannsummary.log
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        DIA-NN: \$(diann 2>&1 | grep "DIA-NN" | grep -oP "\\d+\\.\\d+(\\.\\w+)*(\\.[\\d]+)?")
    END_VERSIONS
    """
}
