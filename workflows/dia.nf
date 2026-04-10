/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

//
// MODULES: Local to the pipeline
//
include { DIANN_MSSTATS               } from '../modules/local/diann/diann_msstats/main'
include { PRELIMINARY_ANALYSIS        } from '../modules/local/diann/preliminary_analysis/main'
include { ASSEMBLE_EMPIRICAL_LIBRARY  } from '../modules/local/diann/assemble_empirical_library/main'
include { INSILICO_LIBRARY_GENERATION } from '../modules/local/diann/insilico_library_generation/main'
include { INDIVIDUAL_ANALYSIS         } from '../modules/local/diann/individual_analysis/main'
include { FINAL_QUANTIFICATION        } from '../modules/local/diann/final_quantification/main'

//
// SUBWORKFLOWS: Consisting of a mix of local and nf-core/modules
//

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/


workflow DIA {
    take:
    ch_file_preparation_results
    ch_expdesign
    ch_diann_cfg

    main:

    ch_software_versions = channel.empty()

    // Version guard for DDA mode (when explicitly set via param)
    if (params.diann_dda && VersionUtils.versionLessThan(params.diann_version, '2.3.2')) {
        error("DDA mode (--diann_dda) requires DIA-NN >= 2.3.2. Current version: ${params.diann_version}. Use -profile diann_v2_3_2")
    }

    // Version guard for InfinDIA
    if (params.enable_infin_dia && VersionUtils.versionLessThan(params.diann_version, '2.3.0')) {
        error("InfinDIA requires DIA-NN >= 2.3.0. Current version: ${params.diann_version}. Use -profile diann_v2_3_2")
    }

    // Version guard for scoring mode
    if (params.scoring_mode == 'proteoforms' && VersionUtils.versionLessThan(params.diann_version, '2.0')) {
        error("--proteoforms scoring mode requires DIA-NN >= 2.0. Current version: ${params.diann_version}. Use -profile diann_v2_1_0 or later")
    }

    // Version guard for DIA-NN 2.0+ features
    if ((params.diann_light_models || params.diann_export_quant || params.diann_site_ms1_quant) && VersionUtils.versionLessThan(params.diann_version, '2.0')) {
        def enabled = []
        if (params.diann_light_models) enabled << '--light-models'
        if (params.diann_export_quant) enabled << '--export-quant'
        if (params.diann_site_ms1_quant) enabled << '--site-ms1-quant'
        error("${enabled.join(', ')} require DIA-NN >= 2.0. Current version: ${params.diann_version}. Use -profile diann_v2_1_0 or later")
    }

    ch_searchdb = channel.fromPath(params.database, checkIfExists: true)
        .ifEmpty { error("No protein database found at '${params.database}'. Provide --database <path/to/proteins.fasta>") }
        .first()

    ch_file_preparation_results.multiMap {
        result ->
        meta:   preprocessed_meta(result[0])
        ms_file:result[1]
    }.set { ch_result }

    ch_experiment_meta = ch_result.meta.unique { m -> m.experiment_id }
        .ifEmpty { error("No valid input files found after SDRF parsing. Check your SDRF file and input paths.") }
        .first()

    // Determine DDA mode: true if explicitly set via param OR auto-detected from SDRF
    ch_is_dda = ch_experiment_meta.map { meta ->
        def dda = params.diann_dda || meta.acquisition_method == 'dda'
        if (dda && VersionUtils.versionLessThan(params.diann_version, '2.3.2')) {
            error("DDA mode (detected from SDRF) requires DIA-NN >= 2.3.2. Current version: ${params.diann_version}. Use -profile diann_v2_3_2")
        }
        return dda
    }

    // diann_config.cfg comes directly from SDRF_PARSING (convert-diann)
    // Use as value channel so it can be consumed by all per-file processes
    ch_diann_cfg_val = ch_diann_cfg

    //
    // MODULE: SILICOLIBRARYGENERATION
    //
    if (params.diann_speclib != null && params.diann_speclib.toString() != "") {
        speclib = channel.from(file(params.diann_speclib, checkIfExists: true))
    } else {
        INSILICO_LIBRARY_GENERATION(ch_searchdb, ch_diann_cfg_val, ch_is_dda)
        speclib = INSILICO_LIBRARY_GENERATION.out.predict_speclib
    }

    if (params.skip_preliminary_analysis) {
        // Users who skip preliminary analysis provide mass accuracy and scan window directly
        ch_parsed_vals = channel.value("${params.mass_acc_ms2},${params.mass_acc_ms1},${params.scan_window}")
        indiv_fin_analysis_in = ch_file_preparation_results
            .combine(ch_searchdb)
            .combine(speclib)
            .combine(ch_parsed_vals)
            .map { meta_map, ms_file, fasta, library, param_string ->
                def values = param_string.trim().split(',')
                def new_meta = meta_map + [
                    mass_acc_ms2 : values[0],
                    mass_acc_ms1 : values[1],
                    scan_window  : values[2]
                ]
                return [ new_meta, ms_file, fasta, library ]
            }
        empirical_lib = speclib
    } else {
        //
        // MODULE: PRELIMINARY_ANALYSIS
        //
        if (params.random_preanalysis) {
            preanalysis_subset = ch_file_preparation_results
                .toSortedList{ a, b -> file(a[1]).getName() <=> file(b[1]).getName() }
                .flatMap()
                .randomSample(params.empirical_assembly_ms_n, params.random_preanalysis_seed)
            empirical_lib_files = preanalysis_subset
                .map { result -> result[1] }
                .collect( sort: { a, b -> file(a).getName() <=> file(b).getName() } )
            PRELIMINARY_ANALYSIS(preanalysis_subset.combine(speclib), ch_diann_cfg_val)
        } else {
            empirical_lib_files = ch_file_preparation_results
                .map { result -> result[1] }
                .collect( sort: { a, b -> file(a).getName() <=> file(b).getName() } )
            PRELIMINARY_ANALYSIS(ch_file_preparation_results.combine(speclib), ch_diann_cfg_val)
        }
        ch_software_versions = ch_software_versions
            .mix(PRELIMINARY_ANALYSIS.out.versions)

        //
        // MODULE: ASSEMBLE_EMPIRICAL_LIBRARY
        //
        // Order matters in DIANN, This should be sorted for reproducible results.
        ASSEMBLE_EMPIRICAL_LIBRARY(
            empirical_lib_files,
            ch_experiment_meta,
            PRELIMINARY_ANALYSIS.out.diann_quant.collect(),
            speclib,
            ch_diann_cfg_val
        )
        ch_software_versions = ch_software_versions
            .mix(ASSEMBLE_EMPIRICAL_LIBRARY.out.versions)
        // Parse calibrated params from the assembly log on the head node
        ch_parsed_vals = ASSEMBLE_EMPIRICAL_LIBRARY.out.log
            .map { log_file ->
                def match = log_file.text.readLines().find { it.contains("Averaged recommended settings") }
                if (match) {
                    def parts = match.trim().split(/\s+/)
                    def ms2 = parts.size() > 10 ? parts[10].replaceAll(/[^0-9.]/, '') : "${params.mass_acc_ms2}"
                    def ms1 = parts.size() > 14 ? parts[14].replaceAll(/[^0-9.]/, '') : "${params.mass_acc_ms1}"
                    def sw  = parts.size() > 18 ? parts[18].replaceAll(/[^0-9.]/, '') : "${params.scan_window}"
                    return "${ms2},${ms1},${sw}"
                }
                return "${params.mass_acc_ms2},${params.mass_acc_ms1},${params.scan_window}"
            }
        indiv_fin_analysis_in = ch_file_preparation_results
            .combine(ch_searchdb)
            .combine(ASSEMBLE_EMPIRICAL_LIBRARY.out.empirical_library)
            .combine(ch_parsed_vals)
            .map { meta_map, ms_file, fasta, library, param_string ->
                def values = param_string.trim().split(',')
                def new_meta = meta_map + [
                    mass_acc_ms2 : values[0],
                    mass_acc_ms1 : values[1],
                    scan_window  : values[2]
                ]
                return [ new_meta, ms_file, fasta, library ]
            }
        empirical_lib = ASSEMBLE_EMPIRICAL_LIBRARY.out.empirical_library
    }

    //
    // MODULE: INDIVIDUAL_ANALYSIS
    //
    INDIVIDUAL_ANALYSIS(indiv_fin_analysis_in, ch_diann_cfg_val)
    ch_software_versions = ch_software_versions
        .mix(INDIVIDUAL_ANALYSIS.out.versions)

    //
    // MODULE: DIANNSUMMARY
    //
    // Order matters in DIANN, This should be sorted for reproducible results.
    // NOTE: ch_results.ms_file contains the name of the ms file, not the path.
    // The next step only needs the name (since it uses the cached .quant)
    // Converting to a file object and using its name is necessary because ch_result.ms_file contains
    // locally, every element in ch_result is a string, whilst on cloud it is a path.
    ch_result
        .ms_file.map { msfile -> file(msfile).getName() }
        .collect(sort: true)
        .set { ms_file_names }

    FINAL_QUANTIFICATION(
        ms_file_names,
        ch_experiment_meta,
        empirical_lib,
        INDIVIDUAL_ANALYSIS.out.diann_quant.collect(),
        ch_searchdb,
        ch_diann_cfg_val)

    ch_software_versions = ch_software_versions.mix(
        FINAL_QUANTIFICATION.out.versions
    )

    diann_main_report = FINAL_QUANTIFICATION.out.main_report

    //
    // MODULE: DIANN_MSSTATS — Convert DIA-NN report to MSstats-compatible format
    //
    DIANN_MSSTATS(
        diann_main_report,
        ch_expdesign
    )
    ch_software_versions = ch_software_versions
        .mix(DIANN_MSSTATS.out.versions)

    emit:
    versions                = ch_software_versions
    diann_report            = diann_main_report
    diann_log               = FINAL_QUANTIFICATION.out.log
    msstats_in              = DIANN_MSSTATS.out.out_msstats
}

// remove meta.id to make sure cache identical HashCode
def preprocessed_meta(LinkedHashMap meta) {
    def parameters = [:]
    parameters['experiment_id']                 = meta.experiment_id
    parameters['acquisition_method']            = meta.acquisition_method
    parameters['dissociationmethod']            = meta.dissociationmethod
    parameters['labelling_type']                = meta.labelling_type
    parameters['fixedmodifications']            = meta.fixedmodifications
    parameters['variablemodifications']         = meta.variablemodifications
    parameters['precursormasstolerance']        = meta.precursormasstolerance
    parameters['precursormasstoleranceunit']    = meta.precursormasstoleranceunit
    parameters['fragmentmasstolerance']         = meta.fragmentmasstolerance
    parameters['fragmentmasstoleranceunit']     = meta.fragmentmasstoleranceunit
    parameters['enzyme']                        = meta.enzyme
    parameters['ms1minmz']                      = meta.ms1minmz
    parameters['ms1maxmz']                      = meta.ms1maxmz
    parameters['ms2minmz']                      = meta.ms2minmz
    parameters['ms2maxmz']                      = meta.ms2maxmz

    return parameters
}

/*
========================================================================================
    THE END
========================================================================================
*/
