//
// Create channel for input file (DIA-NN only pipeline)
//
include { SDRF_PARSING } from '../../../modules/local/sdrf_parsing/main'



workflow CREATE_INPUT_CHANNEL {
    take:
    ch_sdrf

    main:
    ch_versions = channel.empty()

    // Validate --local_input_type against supported local file formats when using --root_folder.
    // Redundant with the schema enum, but still catches the case where schema validation is disabled.
    def allowedLocalInputTypes = ['mzML', 'raw', 'd', 'dia', 'd.tar', 'd.tar.gz', 'd.zip', 'wiff']
    if (params.root_folder && params.local_input_type && !allowedLocalInputTypes.contains(params.local_input_type)) {
        exit(1, "ERROR: Unsupported --local_input_type '${params.local_input_type}'. Supported values: ${allowedLocalInputTypes.join(', ')}")
    }

    // Known raw-data extensions; order matters, so strip longest/compound ones first
    // so 'sample.d.zip' -> 'sample', not 'sample.d'.
    def knownRawExts = ['.d.tar.gz', '.d.tar', '.d.zip', '.mzML.gz', '.raw.gz',
                        '.mzML', '.raw', '.dia', '.d', '.wiff']

    // Always parse as SDRF using DIA-NN converter
    SDRF_PARSING(ch_sdrf)
    ch_versions = ch_versions.mix(SDRF_PARSING.out.versions)
    ch_expdesign = SDRF_PARSING.out.ch_expdesign
    ch_diann_cfg = SDRF_PARSING.out.ch_diann_cfg


    // Extract experiment_id from the SDRF filename
    ch_experiment_id = ch_sdrf.map { sdrf_file -> file(sdrf_file).baseName }

    ch_experiment_id
        .combine(ch_expdesign)
        .splitCsv(header: true, sep: '\t')
        .map { experiment_id, row ->
            def filestr
            def is_wiff = (row.IsWiff?.toString()?.toLowerCase() == 'true')

            if (!params.root_folder) {
                filestr = row.URI?.toString()?.trim() ? row.URI.toString() : row.Filename.toString()

                if (is_wiff) {
                    def scan_filestr = row.Associated_URI?.toString()?.trim() ? row.Associated_URI.toString() : filestr + ".scan"
                    filestr = [filestr, scan_filestr]
                }
            } else {
                filestr = row.Filename.toString()
                filestr = params.root_folder + File.separator + filestr
                if (params.local_input_type) {
                    // Strip the longest matching known raw-data extension (covers
                    // compound suffixes like .d.zip / .d.tar.gz from the SDRF),
                    // then append the target extension.
                    def stem = filestr
                    def stemLower = stem.toLowerCase()

                    def matched = knownRawExts.find { ext ->
                        stemLower.endsWith(ext.toLowerCase())
                    }

                    if (matched) {
                        stem = stem.substring(0, stem.length() - matched.length())
                    } else if (stem.lastIndexOf('.') > 0) {
                        stem = stem.take(stem.lastIndexOf('.'))
                    }
                    filestr = stem + '.' + params.local_input_type
                }

                if (is_wiff) {
                    filestr = [filestr, filestr + ".scan"]
                }
            }
            return [filestr, experiment_id, row]
        }
        .groupTuple(by: 0)
        .map { filestr, experiment_ids, rows ->
            def experiment_id = experiment_ids[0]
            def is_wiff = (rows[0].IsWiff?.toString()?.toLowerCase() == 'true')
            def wrapper = [acquisition_method: "", experiment_id: experiment_id]
            return create_meta_channel_grouped(filestr, rows, wrapper)
        }
        .set { ch_meta_config_dia }

    emit:
    ch_meta_config_dia // [meta, spectra_file]
    ch_expdesign
    ch_diann_cfg
    versions = ch_versions
}

// Function to get list of [meta, [ spectra_files ]]
def create_meta_channel_grouped(def filestr, List rows, Map wrapper) {
    def meta = [:]

    def base_row = rows[0]

    def main_file_str = filestr instanceof List ? filestr[0] : filestr
    def fileName = file(main_file_str).name
    def dotIndex = fileName.lastIndexOf('.')
    meta.id = dotIndex > 0 ? fileName.take(dotIndex) : fileName
    meta.experiment_id = wrapper.experiment_id

    meta.is_wiff = (base_row.IsWiff?.toString()?.toLowerCase() == 'true')

    // existence check
    def files_to_check = filestr instanceof List ? filestr : [filestr]
    files_to_check.each { f ->
        if (!file(f).exists()) {
            exit(1, "ERROR: Please check input file -> File Uri does not exist!\n${f}")
        }
    }

    // Detect acquisition method from SDRF or fallback to --dda param
    def acqMethod = base_row.AcquisitionMethod?.toString()?.trim() ?: ""
    if (acqMethod.toLowerCase().contains("data-independent acquisition") || acqMethod.toLowerCase().contains("dia")) {
        meta.acquisition_method = "dia"
    } else if (acqMethod.toLowerCase().contains("data-dependent acquisition") || acqMethod.toLowerCase().contains("dda")) {
        meta.acquisition_method = "dda"
    } else if (acqMethod.isEmpty()) {
        meta.acquisition_method = params.dda ? "dda" : "dia"
    } else {
        log.error("Unsupported acquisition method: '${acqMethod}'. This pipeline supports DIA and DDA. Found in file: ${filestr}")
        exit(1)
    }

    meta.dissociationmethod = base_row.DissociationMethod?.toString()?.trim() ?: ""
    wrapper.acquisition_method = meta.acquisition_method

    def labels = rows.collect { it.Label?.toString()?.trim() }.findAll { it }.unique()
    meta.labelling_type = labels.join(';')

    def is_plexdia = labels.size() > 1 || (labels.size() == 1 && !labels[0].toLowerCase().contains("label free"))
    meta.plexdia = is_plexdia

    def enzymes = rows.collect { it.Enzyme?.toString()?.trim() }.findAll { it }.unique()
    if (enzymes.size() > 1) {
        log.error("Currently only one enzyme is supported per file. Found conflicting enzymes for ${filestr}: '${enzymes}'.")
        exit(1)
    }
    meta.enzyme = enzymes ? enzymes[0] : null

    def fixedMods = rows.collect { it.FixedModifications?.toString()?.trim() }.findAll { it }.unique()
    if (fixedMods.size() > 1) {
        log.error("SDRF conflict: Multiple FixedModifications (${fixedMods.join(',')}) found for file ${meta.id}. Please fix the SDRF.")
    }
    meta.fixedmodifications = fixedMods ? fixedMods[0] : null

    // Validate required SDRF columns
    def requiredColumns = [
        'Label': meta.labelling_type,
        'Enzyme': meta.enzyme,
        'FixedModifications': meta.fixedmodifications
    ]

    def missingColumns = []
    requiredColumns.each { colName, colValue ->
        if (colValue == null || colValue.toString().isEmpty()) {
            missingColumns.add(colName)
        }
    }

    if (missingColumns.size() > 0) {
        log.error("ERROR: Missing or empty required SDRF columns for file '${filestr}': ${missingColumns.join(', ')}")
        log.error("These parameters must be specified in the SDRF file. Please check your SDRF annotation.")
        exit(1)
    }

    def validUnits = ['ppm', 'da', 'Da', 'PPM']

    if (base_row.PrecursorMassTolerance != null && !base_row.PrecursorMassTolerance.toString().trim().isEmpty()) {
        try {
            meta.precursormasstolerance = Double.parseDouble(base_row.PrecursorMassTolerance)
        } catch (NumberFormatException e) {
            log.error("ERROR: Invalid PrecursorMassTolerance value '${base_row.PrecursorMassTolerance}' for file '${filestr}'. Must be a valid number.")
            exit(1)
        }
    } else {
        log.warn("No precursor mass tolerance in SDRF for '${filestr}'. Using default: ${params.precursor_mass_tolerance} ${params.precursor_mass_tolerance_unit}")
        meta.precursormasstolerance = params.precursor_mass_tolerance
    }

    if (base_row.PrecursorMassToleranceUnit != null && !base_row.PrecursorMassToleranceUnit.toString().trim().isEmpty()) {
        if (!validUnits.any { base_row.PrecursorMassToleranceUnit.toString().equalsIgnoreCase(it) }) {
            log.error("ERROR: Invalid PrecursorMassToleranceUnit '${base_row.PrecursorMassToleranceUnit}' for file '${filestr}'. Must be 'ppm' or 'Da'.")
            exit(1)
        }
        meta.precursormasstoleranceunit = base_row.PrecursorMassToleranceUnit
    } else {
        meta.precursormasstoleranceunit = params.precursor_mass_tolerance_unit
    }

    if (base_row.FragmentMassTolerance != null && !base_row.FragmentMassTolerance.toString().trim().isEmpty()) {
        try {
            meta.fragmentmasstolerance = Double.parseDouble(base_row.FragmentMassTolerance)
        } catch (NumberFormatException e) {
            log.error("ERROR: Invalid FragmentMassTolerance value '${base_row.FragmentMassTolerance}' for file '${filestr}'. Must be a valid number.")
            exit(1)
        }
    } else {
        log.warn("No fragment mass tolerance in SDRF for '${filestr}'. Using default: ${params.fragment_mass_tolerance} ${params.fragment_mass_tolerance_unit}")
        meta.fragmentmasstolerance = params.fragment_mass_tolerance
    }

    if (base_row.FragmentMassToleranceUnit != null && !base_row.FragmentMassToleranceUnit.toString().trim().isEmpty()) {
        if (!validUnits.any { base_row.FragmentMassToleranceUnit.toString().equalsIgnoreCase(it) }) {
            log.error("ERROR: Invalid FragmentMassToleranceUnit '${base_row.FragmentMassToleranceUnit}' for file '${filestr}'. Must be 'ppm' or 'Da'.")
            exit(1)
        }
        meta.fragmentmasstoleranceunit = base_row.FragmentMassToleranceUnit
    } else {
        meta.fragmentmasstoleranceunit = params.fragment_mass_tolerance_unit
    }

    if (base_row.VariableModifications != null && !base_row.VariableModifications.toString().trim().isEmpty()) {
        meta.variablemodifications = base_row.VariableModifications
    } else {
        meta.variablemodifications = params.variable_mods
    }

    meta.ms1minmz = base_row.MS1MinMz?.toString()?.trim() ?: ""
    meta.ms1maxmz = base_row.MS1MaxMz?.toString()?.trim() ?: ""
    meta.ms2minmz = base_row.MS2MinMz?.toString()?.trim() ?: ""
    meta.ms2maxmz = base_row.MS2MaxMz?.toString()?.trim() ?: ""

    def resolved_files = filestr instanceof List ? filestr.collect { file(it) } : file(filestr)
    return [meta, resolved_files]
}
