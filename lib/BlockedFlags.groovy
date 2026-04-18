/**
 * Centralised registry of DIA-NN flags managed by the pipeline.
 *
 * WHY THIS EXISTS:
 * The pipeline controls certain DIA-NN flags directly (e.g. --threads, --out, --qvalue)
 * based on pipeline parameters, SDRF metadata, or step-specific logic. If a user also
 * passes these via --extra_args, the flag would appear twice in the DIA-NN command —
 * causing silent conflicts or undefined behaviour. This registry strips managed flags
 * from extra_args with a warning, so the pipeline's values always take precedence.
 *
 * WHY A GROOVY CLASS AND NOT CONFIG FILES:
 * Blocked flags are a safety mechanism. Defining them in Nextflow config (e.g. via
 * ext.blocked_flags) would allow users to accidentally override or disable them in
 * custom configs. A compiled Groovy class in lib/ cannot be overridden by user configs,
 * ensuring the safety net is always active. It also provides a single file to audit
 * and edit when adding new managed flags.
 *
 * HOW TO ADD A NEW BLOCKED FLAG:
 * - If the flag applies to ALL DIA-NN steps, add it to the COMMON list below.
 * - If it applies to specific steps only, add it to the relevant MODULE_FLAGS entry.
 * - No changes needed in the module .nf files — they call BlockedFlags.strip() which
 *   reads from this registry automatically.
 *
 * Nextflow auto-loads all classes in lib/, so this is available in all modules.
 */
class BlockedFlags {

    // Flags common to ALL DIA-NN steps.
    // These are always set by the pipeline from config/SDRF, so user overrides would conflict.
    //   --temp/--threads/--verbose: controlled by Nextflow task resources and debug_level param
    //   --lib/--f/--fasta: set from workflow inputs (speclib, ms_files, database)
    //   --var-mod/--fixed-mod/--monitor-mod/--channels/--lib-fixed-mod/--original-mods: injected from diann_config.cfg
    //   --dda: auto-detected from SDRF or set via --dda param
    //   --proteoforms/--peptidoforms/--no-peptidoforms: controlled by scoring_mode param
    //   --parent: container-managed (DIA-NN model path), overriding breaks model discovery
    //   --aa-eq: controlled by aa_eq param
    private static final List<String> COMMON = [
        '--temp', '--threads', '--verbose', '--lib', '--f', '--fasta',
        '--monitor-mod', '--var-mod', '--fixed-mod', '--dda', '--parent', '--aa-eq',
        '--channels', '--lib-fixed-mod', '--original-mods',
        '--proteoforms', '--peptidoforms', '--no-peptidoforms',
    ]

    // Per-module additional blocked flags (on top of COMMON).
    //
    // Flags are blocked for two reasons:
    //   1. "Pipeline-managed": the pipeline sets them explicitly from params/SDRF/metadata.
    //      Allowing user overrides would create duplicate/conflicting flags.
    //   2. "No-effect guard": the flag has no effect in this step (e.g., protein inference
    //      during library assembly). Blocking prevents users from passing them and wrongly
    //      believing they had an effect.
    //
    // When reason is non-obvious, a comment explains why the flag is blocked.
    private static final Map<String, List<String>> MODULE_FLAGS = [
        INSILICO_LIBRARY_GENERATION: [
            // Pipeline-managed: set from params (library generation settings)
            '--use-quant', '--no-main-report', '--matrices', '--out',
            '--fasta-search', '--predictor', '--gen-spec-lib',
            '--missed-cleavages', '--min-pep-len', '--max-pep-len',
            '--min-pr-charge', '--max-pr-charge', '--var-mods',
            '--min-pr-mz', '--max-pr-mz', '--min-fr-mz', '--max-fr-mz',
            '--met-excision', '--light-models',
            '--infin-dia', '--pre-select',
            // Pipeline-managed when fine-tuning: tuned model files passed as process inputs
            '--tokens', '--rt-model', '--im-model', '--fr-model',
        ],
        PRELIMINARY_ANALYSIS: [
            // Pipeline-managed: set from params and SDRF calibration metadata
            '--use-quant', '--gen-spec-lib', '--out-lib', '--matrices', '--out',
            '--mass-acc', '--mass-acc-ms1', '--window',
            '--quick-mass-acc', '--min-corr', '--corr-diff', '--time-corr-only',
            '--min-pr-mz', '--max-pr-mz', '--min-fr-mz', '--max-fr-mz',
            // Pipeline-managed: preliminary step disables protein inference (--no-prot-inf)
            '--no-prot-inf',
        ],
        ASSEMBLE_EMPIRICAL_LIBRARY: [
            // Pipeline-managed: set from params and calibration results
            '--no-main-report', '--no-ifs-removal', '--matrices', '--out',
            '--mass-acc', '--mass-acc-ms1', '--window',
            '--individual-mass-acc', '--individual-windows',
            '--out-lib', '--use-quant', '--gen-spec-lib', '--rt-profiling',
            // No-effect guard: protein inference flags have no effect during library assembly
            // (--gen-spec-lib produces a spectral library, not a quantified report).
            // Blocked to prevent users from thinking they affect this step.
            '--no-prot-inf', '--relaxed-prot-inf', '--pg-level',
        ],
        INDIVIDUAL_ANALYSIS: [
            // Pipeline-managed: set from params and calibrated values from assembly step
            '--use-quant', '--gen-spec-lib', '--out-lib', '--matrices', '--out', '--rt-profiling',
            '--mass-acc', '--mass-acc-ms1', '--window',
            '--no-ifs-removal', '--no-main-report',
            // Pipeline-managed: protein inference set by pipeline (--relaxed-prot-inf --pg-level)
            '--relaxed-prot-inf', '--pg-level',
            '--min-pr-mz', '--max-pr-mz', '--min-fr-mz', '--max-fr-mz',
            '--no-prot-inf',
        ],
        FINAL_QUANTIFICATION: [
            // Pipeline-managed: set from params for final report generation
            '--no-main-report', '--gen-spec-lib', '--out-lib', '--no-ifs-removal',
            '--use-quant', '--matrices', '--out',
            // Pipeline-managed: protein inference (--relaxed-prot-inf --pg-level)
            '--relaxed-prot-inf', '--pg-level',
            // Pipeline-managed: FDR controls (precursor_qvalue, matrix_qvalue, matrix_spec_q)
            '--qvalue', '--matrix-qvalue', '--matrix-spec-q',
            '--window', '--individual-windows',
            '--species-genes', '--report-decoys', '--xic', '--no-norm',
            '--export-quant', '--site-ms1-quant',
            '--channel-run-norm', '--channel-spec-norm',
            '--no-prot-inf',
        ],
        FINE_TUNE_MODELS: [
            // Pipeline-managed: tuning flags set from enable_fine_tuning, tune_fr, tune_lr params
            '--tune-lib', '--tune-rt', '--tune-im', '--tune-fr', '--tune-lr',
            '--tune-restrict-layers', '--tune-level',
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
