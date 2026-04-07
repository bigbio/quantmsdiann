/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryMap } from 'plugin/nf-schema'
include { paramsSummaryMultiqc } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_quantms_pipeline'

// Main subworkflows imported from the pipeline DIA
include { DIA } from './dia'

// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
include { INPUT_CHECK } from '../subworkflows/local/input_check/main'
include { FILE_PREPARATION } from '../subworkflows/local/file_preparation/main'
include { CREATE_INPUT_CHANNEL } from '../subworkflows/local/create_input_channel/main'

// Modules import from the pipeline
include { PMULTIQC as SUMMARY_PIPELINE } from '../modules/local/pmultiqc/main'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/


workflow QUANTMSDIANN {

    main:

    ch_versions = channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK(
        file(params.input)
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // SUBWORKFLOW: Create input channel
    //
    CREATE_INPUT_CHANNEL(
        INPUT_CHECK.out.ch_input_file
    )
    ch_versions = ch_versions.mix(CREATE_INPUT_CHANNEL.out.versions)

    //
    // SUBWORKFLOW: File preparation
    //
    FILE_PREPARATION(
        CREATE_INPUT_CHANNEL.out.ch_meta_config_dia
    )

    ch_versions = ch_versions.mix(FILE_PREPARATION.out.versions)

    FILE_PREPARATION.out.results
        .branch { item ->
            dia: item[0].acquisition_method.toLowerCase().contains("dia") || item[0].acquisition_method.toLowerCase().contains("dda")
        }
        .set { ch_fileprep_result }
    //
    // WORKFLOW: Run main bigbio/quantmsdiann analysis pipeline based on the quantification type
    //
    ch_pipeline_results = channel.empty()
    ch_ids_pmultiqc = channel.empty()
    ch_msstats_in = channel.empty()
    ch_consensus_pmultiqc = channel.empty()

    DIA(
        ch_fileprep_result.dia,
        CREATE_INPUT_CHANNEL.out.ch_expdesign,
        CREATE_INPUT_CHANNEL.out.ch_diann_cfg,
    )
    ch_pipeline_results = ch_pipeline_results.mix(DIA.out.diann_report)
    ch_msstats_in = ch_msstats_in.mix(DIA.out.msstats_in)
    ch_versions = ch_versions.mix(DIA.out.versions)

    // Other subworkflow will return null when performing another subworkflow due to unknown reason.
    ch_versions = ch_versions.filter { v -> v != null }

    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_' + 'quantmsdiann_software_' + 'mqc_' + 'versions.yml',
            sort: true,
            newLine: true,
        )
        .set { ch_collated_versions }

    ch_multiqc_config = channel.fromPath("${projectDir}/assets/multiqc_config.yml", checkIfExists: true)
    summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description
        ? file(params.multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    // concatenate multiqc input files
    ch_multiqc_files = channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_config)
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(FILE_PREPARATION.out.statistics)
    ch_multiqc_files = ch_multiqc_files.mix(DIA.out.diann_log)
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: false))

    // create cross product of all inputs
    multiqc_inputs = CREATE_INPUT_CHANNEL.out.ch_expdesign
        .mix(ch_pipeline_results.ifEmpty([]))
        .mix(ch_multiqc_files.collect())
        .mix(ch_ids_pmultiqc.collect().ifEmpty([]))
        .mix(ch_consensus_pmultiqc.collect().ifEmpty([]))
        .mix(ch_msstats_in.ifEmpty([]))
        .collect()

    SUMMARY_PIPELINE(multiqc_inputs)

    emit:
    multiqc_report = SUMMARY_PIPELINE.out.ch_pmultiqc_report.toList()
    versions = ch_versions
}
