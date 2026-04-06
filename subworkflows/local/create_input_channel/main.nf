//
// Create channel for input file (DIA-NN only pipeline)
//
include { SDRF_PARSING } from '../../../modules/local/sdrf_parsing/main'



workflow CREATE_INPUT_CHANNEL {
    take:
    ch_sdrf

    main:
    ch_versions = channel.empty()

    // Always parse as SDRF using DIA-NN converter
    SDRF_PARSING(ch_sdrf)
    ch_versions = ch_versions.mix(SDRF_PARSING.out.versions)
    ch_expdesign = SDRF_PARSING.out.ch_expdesign
    ch_diann_cfg = SDRF_PARSING.out.ch_diann_cfg

    def enzymes = new HashSet()
    def files = new HashSet()

    // Extract experiment_id from the SDRF filename via the value channel
    ch_sdrf_val = ch_sdrf.first()
    ch_experiment_id = ch_sdrf_val.map { sdrf_file -> file(sdrf_file).baseName }

    ch_experiment_id
        .combine(ch_expdesign)
        .splitCsv(header: true, sep: '\t')
        .map { experiment_id, row ->
            def wrapper = [acquisition_method: "", experiment_id: experiment_id]
            create_meta_channel(row, enzymes, files, wrapper)
        }
        .set { ch_meta_config_dia }

    emit:
    ch_meta_config_dia // [meta, spectra_file]
    ch_expdesign
    ch_diann_cfg
    versions = ch_versions
}

// Function to get list of [meta, [ spectra_files ]]
def create_meta_channel(LinkedHashMap row, enzymes, files, wrapper) {
    def meta = [:]
    def filestr

    // Always use SDRF format
    if (!params.root_folder) {
        filestr = row.URI?.toString()?.trim() ? row.URI.toString() : row.Filename.toString()
    }
    else {
        filestr = row.Filename.toString()
    }

    def fileName = file(filestr).name
    def dotIndex = fileName.lastIndexOf('.')
    meta.id = dotIndex > 0 ? fileName.take(dotIndex) : fileName
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
    // AcquisitionMethod is already extracted by convert-diann (e.g. "Data-Independent Acquisition")
    def acqMethod = row.AcquisitionMethod?.toString()?.trim() ?: ""
    if (acqMethod.toLowerCase().contains("data-independent acquisition") || acqMethod.toLowerCase().contains("dia")) {
        meta.acquisition_method = "dia"
    }
    else if (acqMethod.isEmpty()) {
        // If no acquisition method column in SDRF, assume DIA (this is a DIA-only pipeline)
        meta.acquisition_method = "dia"
    }
    else {
        log.error("This pipeline only supports Data-Independent Acquisition (DIA). Found: '${acqMethod}'. Use the quantms pipeline for DDA workflows.")
        exit(1)
    }

    // DissociationMethod is already normalized by convert-diann (HCD, CID, ETD, ECD)
    meta.dissociationmethod = row.DissociationMethod?.toString()?.trim() ?: ""

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
        log.warn("No precursor mass tolerance in SDRF for '${filestr}'. Using default: ${params.precursor_mass_tolerance} ${params.precursor_mass_tolerance_unit}")
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
        log.warn("No fragment mass tolerance in SDRF for '${filestr}'. Using default: ${params.fragment_mass_tolerance} ${params.fragment_mass_tolerance_unit}")
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

    // Per-file scan ranges (empty string = no flags passed, DIA-NN auto-detects)
    meta.ms1minmz = row.MS1MinMz?.toString()?.trim() ?: ""
    meta.ms1maxmz = row.MS1MaxMz?.toString()?.trim() ?: ""
    meta.ms2minmz = row.MS2MinMz?.toString()?.trim() ?: ""
    meta.ms2maxmz = row.MS2MaxMz?.toString()?.trim() ?: ""

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
