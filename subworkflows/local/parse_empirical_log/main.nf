
include { PARSE_EMPIRICAL_LOG_TASK } from '../../../modules/local/parse_empirical_log_task'

workflow PARSE_EMPIRICAL_LOG {
    take:
    ch_log_file

    main:
    PARSE_EMPIRICAL_LOG_TASK(ch_log_file)

    ch_parsed_vals = PARSE_EMPIRICAL_LOG_TASK.out.parsed_vals
        .ifEmpty("${params.mass_acc_ms2},${params.mass_acc_ms1},${params.scan_window}")

    emit:
    parsed_vals = ch_parsed_vals
}
