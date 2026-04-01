process PARSE_EMPIRICAL_LOG_TASK {
    label 'process_single'

    input:
    path log_file

    output:
    stdout emit: parsed_vals

    script:
    """
    val_mass_acc_ms2=\$(grep "Averaged recommended settings" ${log_file} | cut -d ' ' -f 11 | tr -cd "[0-9.]")
    val_mass_acc_ms1=\$(grep "Averaged recommended settings" ${log_file} | cut -d ' ' -f 15 | tr -cd "[0-9.]")
    val_scan_window=\$(grep "Averaged recommended settings" ${log_file} | cut -d ' ' -f 19 | tr -cd "[0-9.]")

    if [ -z "\$val_mass_acc_ms2" ]; then val_mass_acc_ms2=${params.mass_acc_ms2}; fi
    if [ -z "\$val_mass_acc_ms1" ]; then val_mass_acc_ms1=${params.mass_acc_ms1}; fi
    if [ -z "\$val_scan_window" ]; then val_scan_window=${params.scan_window}; fi

    CALIBRATED_PARAMS_VAL="\${val_mass_acc_ms2},\${val_mass_acc_ms1},\${val_scan_window}"

    echo -n "\$CALIBRATED_PARAMS_VAL"
    """
}
