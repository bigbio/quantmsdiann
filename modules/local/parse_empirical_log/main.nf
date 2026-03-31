process PARSE_EMPIRICAL_LOG {
    label 'process_single'

    input:
    path log_file

    output:
    env PARSED_VALS, emit: parsed_vals

    script:
    """
    PARSED_VALS="0,0,0"
    parsed=\$(perl -ne 'if (/Mass accuracy = ([0-9.]+)ppm, MS1 accuracy = ([0-9.]+)ppm, Scan window = ([0-9.]+)/) { print "\$1,\$2,\$3"; exit; }' ${log_file})
    if [ -z "\$parsed" ]; then
        parsed="0,0,0"
    fi
    export PARSED_VALS="\$parsed"
    """
}
