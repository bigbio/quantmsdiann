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
     * Minimum DIA-NN version that supports native Linux Thermo .raw reading.
     * Used by stageInMode closures in DIA-NN per-file process modules.
     */
    static final String NATIVE_RAW_MIN_VERSION = '2.1.0'

    /**
     * Returns true when DIA-NN processes should receive .raw files directly
     * (without prior ThermoRawFileParser conversion), based on pipeline params.
     *
     * @param params  Nextflow params map (must have diann_version and mzml_convert)
     */
    static boolean isNativeRawMode(params) {
        if (params.mzml_convert == false) return true
        if (params.mzml_convert != null) return false
        return versionAtLeast(params.diann_version?.toString() ?: '1.8.1', NATIVE_RAW_MIN_VERSION)
    }
}
