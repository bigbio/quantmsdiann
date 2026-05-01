//
// Raw file conversion and mzml indexing
//

include { THERMORAWFILEPARSER } from '../../../modules/bigbio/thermorawfileparser/main'
include { DECOMPRESS          } from '../../../modules/local/utils/decompress_dotd/main'
include { MZML_INDEXING       } from '../../../modules/local/openms/mzml_indexing/main'
include { MZML_STATISTICS     } from '../../../modules/local/utils/mzml_statistics/main'

workflow FILE_PREPARATION {
    take:
    ch_rawfiles            // channel: [ val(meta), raw/mzml/d.tar ]

    main:
    ch_versions   = channel.empty()
    ch_results    = channel.empty()
    ch_statistics = channel.empty()
    ch_ms2_statistics = channel.empty()
    ch_feature_statistics = channel.empty()


    // Divide the compressed files
    ch_rawfiles
    .branch { item ->
        dottar: hasExtension(item[1], '.tar')
        dotzip: hasExtension(item[1], '.zip')
        gz: hasExtension(item[1], '.gz')
        uncompressed: true
    }.set { ch_branched_input }

    compressed_files = ch_branched_input.dottar.mix(ch_branched_input.dotzip, ch_branched_input.gz)
    DECOMPRESS(compressed_files)
    ch_versions = ch_versions.mix(DECOMPRESS.out.versions)
    ch_rawfiles = ch_branched_input.uncompressed.mix(DECOMPRESS.out.decompressed_files)

    //
    // Resolve whether Thermo .raw should be converted to mzML via TRFP
    // or passed natively to DIA-NN. DIA-NN added native Linux .raw support
    // in 2.1.0; older versions must go through TRFP.
    //
    boolean native_raw_supported = VersionUtils.versionAtLeast(params.diann_version, '2.1.0')
    boolean convert_raw
    if (params.mzml_convert == null) {
        convert_raw = !native_raw_supported
    } else {
        convert_raw = params.mzml_convert as boolean
        if (!convert_raw && !native_raw_supported) {
            error("--mzml_convert false (native .raw) requires DIA-NN >= 2.1.0. " +
                "Current version: ${params.diann_version}. " +
                "Use -profile diann_v2_1_0 (or later) or set --mzml_convert true.")
        }
    }

    // Warn if the user set --mzml_convert but every input is already mzML / .d / .dia
    // (i.e. no Thermo .raw will reach TRFP) — including when --local_input_type mzML
    // overrides SDRF extensions under --root_folder.
    if (params.mzml_convert != null && params.root_folder && params.local_input_type &&
        params.local_input_type.toString().toLowerCase() != 'raw') {
        log.warn "--mzml_convert=${params.mzml_convert} has no effect: " +
            "--local_input_type '${params.local_input_type}' under --root_folder means no Thermo .raw files will be processed."
    }

    //
    // Divide mzml files
    ch_rawfiles
    .branch { item ->
        raw: hasExtension(item[1], '.raw')
        mzML: hasExtension(item[1], '.mzML')
        dotd: hasExtension(item[1], '.d')
        dia: hasExtension(item[1], '.dia')
        unsupported: true
    }.set { ch_branched_input }

    // Warn about unsupported file formats
    ch_branched_input.unsupported
        .collect()
        .subscribe { files ->
            if (files.size() > 0) {
                log.warn "=" * 80
                log.warn "WARNING: ${files.size()} file(s) with unsupported format(s) detected and will be SKIPPED from processing:"
                files.each { _meta, file ->
                    log.warn "  - ${file}"
                }
                log.warn "\nSupported formats: .raw, .mzML, .d (Bruker), .dia"
                log.warn "Compressed variants (.gz, .tar, .tar.gz, .zip) are also supported."
                log.warn "=" * 80
            }
        }

    // Note: we used to always index mzMLs if not already indexed but due to
    //  either a bug or limitation in nextflow
    //  peeking into a remote file consumes a lot of RAM
    //  See https://github.com/bigbio/quantms/issues/61
    //  This is now done in the search engines themselves if they need it.
    //  This means users should pre-index to save time and space, especially
    //  when re-running.

    if (params.reindex_mzml) {
        MZML_INDEXING( ch_branched_input.mzML )
        ch_versions = ch_versions.mix(MZML_INDEXING.out.versions)
        ch_results  = ch_results.mix(MZML_INDEXING.out.mzmls_indexed)
    } else {
        ch_results = ch_results.mix(ch_branched_input.mzML)
    }

    if (convert_raw) {
        // Convert Thermo .raw to .mzML via ThermoRawFileParser (default for DIA-NN < 2.1.0).
        THERMORAWFILEPARSER( ch_branched_input.raw )
        // Output: spectra (tuple val(meta), path(mzML/mgf/parquet)), log, versions via topic channel
        ch_results = ch_results.mix(THERMORAWFILEPARSER.out.spectra)
    } else {
        // Pass Thermo .raw straight through to DIA-NN (native reader, DIA-NN >= 2.1.0).
        // See https://github.com/vdemichev/DiaNN/issues/1468 for known caveats.
        ch_results = ch_results.mix(ch_branched_input.raw)
    }

    ch_results.map{ it -> [it[0], it[1]] }.set{ indexed_mzml_bundle }

    // Pass through .d files without conversion
    // DIA-NN handles .d files natively; they bypass mzML statistics
    ch_results = indexed_mzml_bundle.mix(ch_branched_input.dotd)

    // Pass through .dia files without conversion (DIA-NN handles them natively)
    ch_results = ch_results.mix(ch_branched_input.dia)

    if (params.mzml_statistics) {
        // Only run on mzML files — exclude .d, .dia, .mgf, .parquet, etc.
        ch_mzml_for_stats = ch_results.filter { _meta, file ->
            hasExtension(file, '.mzML')
        }
        MZML_STATISTICS(ch_mzml_for_stats)
        ch_statistics = ch_statistics.mix(MZML_STATISTICS.out.ms_statistics.collect())
        ch_ms2_statistics = ch_ms2_statistics.mix(MZML_STATISTICS.out.ms2_statistics)
        ch_feature_statistics = ch_feature_statistics.mix(MZML_STATISTICS.out.feature_statistics.collect())
        ch_versions = ch_versions.mix(MZML_STATISTICS.out.versions)
    }

    emit:
    results         = ch_results        // channel: [val(mzml_id), indexedmzml|.d.tar]
    statistics      = ch_statistics     // channel: [ *_ms_info.parquet ]
    ms2_statistics  = ch_ms2_statistics // channel: [ *_ms2_info.parquet ]
    feature_statistics = ch_feature_statistics // channel: [ *_feature_info.parquet ]
    versions        = ch_versions       // channel: [ *.versions.yml ]
}

//
// check file extension
//
def hasExtension(file, extension) {
    return file.toString().toLowerCase().endsWith(extension.toLowerCase())
}
