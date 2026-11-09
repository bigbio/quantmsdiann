/**
 * Semantic version comparison utility for DIA-NN version guards.
 *
 * Nextflow auto-loads all classes in lib/, so these are available
 * in workflows and module scripts without explicit imports.
 */
class VersionUtils {

    /**
     * Compare two version strings semantically (e.g. '2.10.0' > '2.3.2').
     * Returns negative if a < b, zero if equal, positive if a > b.
     */
    static int compare(String a, String b) {
        def partsA = a.tokenize('.').collect { it.isInteger() ? it.toInteger() : 0 }
        def partsB = b.tokenize('.').collect { it.isInteger() ? it.toInteger() : 0 }
        def maxLen = Math.max(partsA.size(), partsB.size())
        for (int i = 0; i < maxLen; i++) {
            int va = i < partsA.size() ? partsA[i] : 0
            int vb = i < partsB.size() ? partsB[i] : 0
            if (va != vb) return va <=> vb
        }
        return 0
    }

    /** True if version is strictly less than required. */
    static boolean versionLessThan(String version, String required) {
        return compare(version, required) < 0
    }

    /** True if version is greater than or equal to required. */
    static boolean versionAtLeast(String version, String required) {
        return compare(version, required) >= 0
    }

    /**
     * Resolve the precursor-level q-value (DIA-NN --qvalue and the MSstats
     * --qvalue_threshold) for the configured DIA-NN version.
     *
     * An explicit params.precursor_qvalue ALWAYS wins (any value the user
     * supplied via CLI, -c config or profile is non-null and returned
     * unchanged). When unset (null), DIA-NN's version-dependent recommendation
     * applies: 1% (0.01) for versions before 2.5, 5% (0.05) for 2.5 and later.
     *
     * Takes the two values, not the params map: a process script block that passes
     * `params` puts every parameter into the task hash, including the timestamped
     * `trace_report_suffix`, so `-resume` would re-run the task on every launch (#143).
     *
     * @param precursorQvalue  params.precursor_qvalue (null = version default)
     * @param diannVersion     params.diann_version
     */
    static resolvePrecursorQvalue(precursorQvalue, diannVersion) {
        if (precursorQvalue != null) return precursorQvalue
        def version = diannVersion?.toString() ?: '1.8.1'
        return versionLessThan(version, '2.5') ? 0.01 : 0.05
    }

    /**
     * Minimum DIA-NN version that supports native Linux Thermo .raw reading.
     * Used by stageInMode closures in DIA-NN per-file process modules.
     */
    static final String NATIVE_RAW_MIN_VERSION = '2.1.0'

    /**
     * Returns true when DIA-NN processes should receive .raw files directly
     * (without prior ThermoRawFileParser conversion).
     *
     * Takes the two values, not the params map, for the same reason as
     * resolvePrecursorQvalue (#143).
     *
     * @param mzmlConvert   params.mzml_convert (null = decide by version)
     * @param diannVersion  params.diann_version
     */
    static boolean isNativeRawMode(mzmlConvert, diannVersion) {
        if (mzmlConvert == false) return true
        if (mzmlConvert != null) return false
        return versionAtLeast(diannVersion?.toString() ?: '1.8.1', NATIVE_RAW_MIN_VERSION)
    }
}
