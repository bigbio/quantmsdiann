//
// Create channel for input file (DIA-NN only pipeline)
//
include { SDRF_PARSING } from '../../../modules/local/sdrf_parsing/main'



workflow CREATE_INPUT_CHANNEL {
    take:
    ch_sdrf

    main:
    ch_versions = channel.empty()

    // Always parse as SDRF (OpenMS experimental design format deprecated)
    SDRF_PARSING(ch_sdrf)
    ch_versions = ch_versions.mix(SDRF_PARSING.out.versions)
    ch_config = SDRF_PARSING.out.ch_sdrf_config_file
    ch_expdesign = SDRF_PARSING.out.ch_expdesign

    def Set enzymes = []
    def Set files = []

    def wrapper = [
        acquisition_method: "",
        experiment_id: file(ch_sdrf.toString()).baseName,
    ]

    ch_config
        .splitCsv(header: true, sep: '\t')
        .map { row -> create_meta_channel(row, enzymes, files, wrapper) }
        .set { ch_meta_config_dia }

    emit:
    ch_meta_config_dia // [meta, spectra_file]
    ch_expdesign
    versions = ch_versions
}

// Function to get list of [meta, [ spectra_files ]]
def create_meta_channel(LinkedHashMap row, enzymes, files, wrapper) {
    def meta = [:]
    def filestr

    // Always use SDRF format
    if (!params.root_folder) {
        filestr = row.URI.toString()
    }
    else {
        filestr = row.Filename.toString()
    }

    meta.mzml_id = file(filestr).name.take(file(filestr).name.lastIndexOf('.'))
    meta.experiment_id = wrapper.experiment_id

    // apply transformations given by specified root_folder and type
    if (params.root_folder) {
        filestr = params.root_folder + File.separator + filestr
        filestr = (params.local_input_type
            ? filestr.take(filestr.lastIndexOf('.')) + '.' + params.local_input_type
            : filestr)
    }

    // existence check
    if (!file(filestr).exists()) {
        exit(1, "ERROR: Please check input file -> File Uri does not exist!\n${filestr}")
    }

    // Validate acquisition method is DIA
    if (row["Proteomics Data Acquisition Method"].toString().toLowerCase().contains("data-independent acquisition")) {
        meta.acquisition_method = "dia"
    }
    else {
        log.error("This pipeline only supports Data-Independent Acquisition (DIA). Found: '${row["Proteomics Data Acquisition Method"]}'. Use the quantms pipeline for DDA workflows.")
        exit(1)
    }

    // dissociation method conversion
    if (row.DissociationMethod == "COLLISION-INDUCED DISSOCIATION") {
        meta.dissociationmethod = "CID"
    }
    else if (row.DissociationMethod == "HIGHER ENERGY BEAM-TYPE COLLISION-INDUCED DISSOCIATION") {
        meta.dissociationmethod = "HCD"
    }
    else if (row.DissociationMethod == "ELECTRON TRANSFER DISSOCIATION") {
        meta.dissociationmethod = "ETD"
    }
    else if (row.DissociationMethod == "ELECTRON CAPTURE DISSOCIATION") {
        meta.dissociationmethod = "ECD"
    }
    else {
        meta.dissociationmethod = row.DissociationMethod
    }

    wrapper.acquisition_method = meta.acquisition_method

    // Validate required SDRF columns - these parameters are exclusively read from SDRF (no command-line override)
    def requiredColumns = [
        'Label': row.Label,
        'Enzyme': row.Enzyme,
        'FixedModifications': row.FixedModifications
    ]

    def missingColumns = []
    requiredColumns.each { colName, colValue ->
        if (colValue == null || colValue.toString().trim().isEmpty()) {
            missingColumns.add(colName)
        }
    }

    if (missingColumns.size() > 0) {
        log.error("ERROR: Missing or empty required SDRF columns for file '${filestr}': ${missingColumns.join(', ')}")
        log.error("These parameters must be specified in the SDRF file. Please check your SDRF annotation.")
        exit(1)
    }

    // Set values from SDRF (required columns)
    meta.labelling_type = row.Label
    meta.fixedmodifications = row.FixedModifications
    meta.enzyme = row.Enzyme

    // Set tolerance values: use SDRF if available, otherwise fall back to params
    def validUnits = ['ppm', 'da', 'Da', 'PPM']

    // Precursor mass tolerance
    if (row.PrecursorMassTolerance != null && !row.PrecursorMassTolerance.toString().trim().isEmpty()) {
        try {
            meta.precursormasstolerance = Double.parseDouble(row.PrecursorMassTolerance)
        } catch (NumberFormatException e) {
            log.error("ERROR: Invalid PrecursorMassTolerance value '${row.PrecursorMassTolerance}' for file '${filestr}'. Must be a valid number.")
            exit(1)
        }
    } else {
        meta.precursormasstolerance = params.precursor_mass_tolerance
    }

    // Precursor mass tolerance unit
    if (row.PrecursorMassToleranceUnit != null && !row.PrecursorMassToleranceUnit.toString().trim().isEmpty()) {
        if (!validUnits.any { row.PrecursorMassToleranceUnit.toString().equalsIgnoreCase(it) }) {
            log.error("ERROR: Invalid PrecursorMassToleranceUnit '${row.PrecursorMassToleranceUnit}' for file '${filestr}'. Must be 'ppm' or 'Da'.")
            exit(1)
        }
        meta.precursormasstoleranceunit = row.PrecursorMassToleranceUnit
    } else {
        meta.precursormasstoleranceunit = params.precursor_mass_tolerance_unit
    }

    // Fragment mass tolerance
    if (row.FragmentMassTolerance != null && !row.FragmentMassTolerance.toString().trim().isEmpty()) {
        try {
            meta.fragmentmasstolerance = Double.parseDouble(row.FragmentMassTolerance)
        } catch (NumberFormatException e) {
            log.error("ERROR: Invalid FragmentMassTolerance value '${row.FragmentMassTolerance}' for file '${filestr}'. Must be a valid number.")
            exit(1)
        }
    } else {
        meta.fragmentmasstolerance = params.fragment_mass_tolerance
    }

    // Fragment mass tolerance unit
    if (row.FragmentMassToleranceUnit != null && !row.FragmentMassToleranceUnit.toString().trim().isEmpty()) {
        if (!validUnits.any { row.FragmentMassToleranceUnit.toString().equalsIgnoreCase(it) }) {
            log.error("ERROR: Invalid FragmentMassToleranceUnit '${row.FragmentMassToleranceUnit}' for file '${filestr}'. Must be 'ppm' or 'Da'.")
            exit(1)
        }
        meta.fragmentmasstoleranceunit = row.FragmentMassToleranceUnit
    } else {
        meta.fragmentmasstoleranceunit = params.fragment_mass_tolerance_unit
    }

    // Variable modifications: use SDRF if available, otherwise fall back to params
    if (row.VariableModifications != null && !row.VariableModifications.toString().trim().isEmpty()) {
        meta.variablemodifications = row.VariableModifications
    } else {
        meta.variablemodifications = params.variable_mods
    }

    enzymes += row.Enzyme
    if (enzymes.size() > 1) {
        log.error("Currently only one enzyme is supported for the whole experiment. Specified was '${enzymes}'. Check or split your SDRF.")
        log.error(filestr)
        exit(1)
    }

    // Check for duplicate files
    if (filestr in files) {
        log.error("Currently only one DIA-NN setting per file is supported for the whole experiment. ${filestr} has multiple entries in your SDRF. Consider splitting your design into multiple experiments.")
        exit(1)
    }
    files += filestr

    return [meta, filestr]
}
