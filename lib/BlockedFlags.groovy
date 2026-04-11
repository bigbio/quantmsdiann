/**
 * Centralised registry of DIA-NN flags managed by the pipeline.
 *
 * Each DIA-NN module has a set of flags that the pipeline controls directly.
 * If a user passes any of these via --extra_args, they are stripped with a warning
 * to prevent silent conflicts.
 *
 * Nextflow auto-loads all classes in lib/, so this is available in all modules.
 */
class BlockedFlags {

    // Flags common to ALL DIA-NN steps
    private static final List<String> COMMON = [
        '--temp', '--threads', '--verbose', '--lib', '--f', '--fasta',
        '--monitor-mod', '--var-mod', '--fixed-mod', '--dda',
        '--channels', '--lib-fixed-mod', '--original-mods',
        '--proteoforms', '--peptidoforms', '--no-peptidoforms',
    ]

    // Per-module additional blocked flags (on top of COMMON)
    private static final Map<String, List<String>> MODULE_FLAGS = [
        INSILICO_LIBRARY_GENERATION: [
            '--use-quant', '--no-main-report', '--matrices', '--out',
            '--fasta-search', '--predictor', '--gen-spec-lib',
            '--missed-cleavages', '--min-pep-len', '--max-pep-len',
            '--min-pr-charge', '--max-pr-charge', '--var-mods',
            '--min-pr-mz', '--max-pr-mz', '--min-fr-mz', '--max-fr-mz',
            '--met-excision', '--light-models',
            '--infin-dia', '--pre-select',
        ],
        PRELIMINARY_ANALYSIS: [
            '--use-quant', '--gen-spec-lib', '--out-lib', '--matrices', '--out',
            '--mass-acc', '--mass-acc-ms1', '--window',
            '--quick-mass-acc', '--min-corr', '--corr-diff', '--time-corr-only',
            '--min-pr-mz', '--max-pr-mz', '--min-fr-mz', '--max-fr-mz',
            '--no-prot-inf',
        ],
        ASSEMBLE_EMPIRICAL_LIBRARY: [
            '--no-main-report', '--no-ifs-removal', '--matrices', '--out',
            '--mass-acc', '--mass-acc-ms1', '--window',
            '--individual-mass-acc', '--individual-windows',
            '--out-lib', '--use-quant', '--gen-spec-lib', '--rt-profiling',
            '--no-prot-inf', '--relaxed-prot-inf', '--pg-level',
        ],
        INDIVIDUAL_ANALYSIS: [
            '--use-quant', '--gen-spec-lib', '--out-lib', '--matrices', '--out', '--rt-profiling',
            '--mass-acc', '--mass-acc-ms1', '--window',
            '--no-ifs-removal', '--no-main-report', '--relaxed-prot-inf', '--pg-level',
            '--min-pr-mz', '--max-pr-mz', '--min-fr-mz', '--max-fr-mz',
            '--no-prot-inf',
        ],
        FINAL_QUANTIFICATION: [
            '--no-main-report', '--gen-spec-lib', '--out-lib', '--no-ifs-removal',
            '--use-quant', '--matrices', '--out', '--relaxed-prot-inf', '--pg-level',
            '--qvalue', '--matrix-qvalue', '--matrix-spec-q', '--window', '--individual-windows',
            '--species-genes', '--report-decoys', '--xic', '--no-norm',
            '--export-quant', '--site-ms1-quant',
            '--channel-run-norm', '--channel-spec-norm',
            '--no-prot-inf',
        ],
    ]

    /**
     * Get the full blocked flags list for a module (COMMON + module-specific).
     */
    static List<String> forModule(String moduleName) {
        def moduleFlags = MODULE_FLAGS[moduleName] ?: []
        return (COMMON + moduleFlags).unique()
    }

    /**
     * Strip blocked flags from an args string, logging a warning for each.
     * Returns the cleaned args string.
     *
     * @param moduleName  e.g. 'FINAL_QUANTIFICATION'
     * @param args        the raw args string from task.ext.args
     * @param log         the Nextflow log object
     * @return cleaned args string
     */
    static String strip(String moduleName, String args, def log) {
        if (!args) return ''
        def blocked = forModule(moduleName)
        // Sort by length descending so longer flags (e.g. --mass-acc-ms1) match before shorter prefixes (--mass-acc)
        blocked.sort { a -> -a.length() }.each { flag ->
            def flagPattern = '(?<=^|\\s)' + java.util.regex.Pattern.quote(flag) + '(?=\\s|\$)(\\s+(?!-{1,2}[a-zA-Z])\\S+)*'
            if (args =~ flagPattern) {
                log.warn "DIA-NN: '${flag}' is managed by the pipeline for ${moduleName} and will be stripped."
                args = args.replaceAll(flagPattern, '').trim()
            }
        }
        return args
    }
}
