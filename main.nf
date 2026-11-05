#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    bigbio/quantmsdiann
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/bigbio/quantmsdiann
    Website: https://nf-co.re/quantmsdiann
    Slack  : https://nfcore.slack.com/channels/quantms
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { QUANTMSDIANN  } from './workflows/quantmsdiann'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_quantms_pipeline'
include { checkRenamedParams      } from './subworkflows/local/utils_nfcore_quantms_pipeline'
include { UTILS_NEXTFLOW_PIPELINE   } from './subworkflows/nf-core/utils_nextflow_pipeline'
include { UTILS_NFSCHEMA_PLUGIN     } from './subworkflows/nf-core/utils_nfschema_plugin'


//
// WORKFLOW: Run main bigbio/quantmsdiann analysis pipeline
//
workflow BIGBIO_QUANTMSDIANN {

    main:

    QUANTMSDIANN ()

    emit:
    multiqc_report = QUANTMSDIANN.out.multiqc_report // channel: /path/to/multiqc_report.html
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN ALL WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {

    main:

    // Dump parameters to JSON file for documenting the pipeline settings

    UTILS_NEXTFLOW_PIPELINE (
        false,
        true,
        params.outdir,
        false
    )

    //
    // Fail on parameter names from older releases, then validate against nextflow_schema.json
    //
    checkRenamedParams()

    UTILS_NFSCHEMA_PLUGIN (
        workflow,
        params.validate_params,
        null,
        params.help,
        params.help_full,
        params.show_hidden,
        "",
        "",
        "nextflow run bigbio/quantmsdiann -profile docker --input <sdrf.tsv> --database <fasta> --outdir <outdir>"
    )

    // could take UTILS_NEXTFLOW_PIPELINE.out.samplesheet channel as parsed input
    BIGBIO_QUANTMSDIANN ()

    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
        BIGBIO_QUANTMSDIANN.out.multiqc_report
    )
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
