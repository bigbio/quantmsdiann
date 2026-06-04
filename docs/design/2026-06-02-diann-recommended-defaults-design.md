# DIA-NN recommended defaults

**Date:** 2026-06-02
**Status:** Design — approved, pending spec review

Align two pipeline defaults with current DIA-NN guidance:

1. **Version-dependent precursor q-value** (`--qvalue`).
2. **Disable the "fast-mode" calibration flags** that can drop IDs.

Both came out of discussion with DIA-NN author Vadim Demichev (2026-06-02) and a
prior report (José Nimo) that the fast-mode flags lose identifications.

---

## Change 1 — Version-dependent precursor q-value

### Problem

The precursor-level q-value is a single static default applied for every
version:

```
precursor_qvalue = 0.01   // nextflow.config
```

Used in two places:

- `modules/local/diann/final_quantification/main.nf` → `--qvalue $params.precursor_qvalue`
  (DIA-NN main-report precursor threshold)
- `modules/local/diann/diann_msstats/main.nf` → `--qvalue_threshold $params.precursor_qvalue`
  (precursor q-value when converting the report to MSstats input)

DIA-NN's recommended precursor q-value changed by version: older versions run at
1%, DIA-NN 2.5+ at 5%. A fixed 0.01 ignores that.

### Mapping

| `diann_version`                      | resolved `precursor_qvalue` |
| ------------------------------------ | --------------------------- |
| `< 2.5` (1.8.1, 2.1.0, 2.2.0, 2.3.2) | `0.01` (1%)                 |
| `>= 2.5` (2.5.0 and later)           | `0.05` (5%)                 |

Boundary = `VersionUtils.versionLessThan(diann_version, '2.5')`. An explicit
`--precursor_qvalue` always overrides. This is **precursor-level filtering
only** — both the `--qvalue` flag and the MSstats `--qvalue_threshold` (which
share `precursor_qvalue`) follow this value. The matrix thresholds
`matrix_qvalue` (0.01) and `matrix_spec_q` (0.05) are independent and unchanged.

> Note: Vadim confirmed the fast-mode flags below; the exact precursor-q-value
> mapping is our current best understanding (proceeding with 1.8.1=1%,
> 2.5+=5%) and may be revised if he advises otherwise.

### Override guarantee (hard requirement)

A user-supplied precursor q-value must **never** be overwritten by the
version-dependent default. This holds for every way the user can set it — CLI
`--precursor_qvalue 0.02`, a `-c custom.config`, or a profile — because each
sets `params.precursor_qvalue` to a non-null value and the resolver returns it
unchanged before any version logic runs.

Two conditions make this true and must both be satisfied:

1. **`null` sentinel preserved.** The only way `params.precursor_qvalue` is
   `null` is when the user did not set it. The resolver treats `null` as "auto"
   and any non-null value as an explicit override.
2. **No schema-injected default.** `nextflow_schema.json` must **not** carry
   `"default": 0.01` for `precursor_qvalue`. If it did, the schema layer could
   repopulate the param to `0.01` when the user omits it, making the sentinel
   non-null and silently forcing 1% for every version (defeating both the auto
   default and the override detection). The schema entry therefore drops the
   default and uses `"type": ["number","null"]`.

No other code path may apply its own fallback to `precursor_qvalue` (e.g.
`params.precursor_qvalue ?: 0.01`); resolution happens only via
`resolvePrecursorQvalue`. The two consuming modules
(`final_quantification`, `diann_msstats`) are the only readers and both call the
resolver — no remaining direct `$params.precursor_qvalue` interpolation.

### Design (Approach A: runtime resolver)

Mirror the existing `VersionUtils.isNativeRawMode(params)` pattern: `null`
default = "auto / resolve by version", explicit value overrides, resolution in
one place.

**`nextflow.config`**

```groovy
precursor_qvalue        = null   // --qvalue precursor q-value; null = auto by
                                 // diann_version (<2.5 -> 0.01, >=2.5 -> 0.05).
                                 // Set explicitly to override.
```

**`lib/VersionUtils.groovy`** — add:

```groovy
/**
 * Resolve the precursor-level q-value (DIA-NN --qvalue / MSstats
 * --qvalue_threshold) for the configured DIA-NN version.
 *
 * Explicit params.precursor_qvalue always wins. Otherwise DIA-NN's
 * version-dependent recommendation applies: 1% (0.01) for versions before
 * 2.5, 5% (0.05) for 2.5 and later.
 */
static resolvePrecursorQvalue(params) {
    if (params.precursor_qvalue != null) return params.precursor_qvalue
    def version = params.diann_version?.toString() ?: '1.8.1'
    return versionLessThan(version, '2.5') ? 0.01 : 0.05
}
```

**`nextflow_schema.json`** — current entry is `{"type":"number","default":0.01}`.
Since the default becomes `null`: set `"type": ["number","null"]`, drop/null the
`"default"`, and update the description to state the auto/version-dependent
behavior with the mapping.

**Consuming modules** — resolve once and interpolate the local:

- `final_quantification/main.nf`: `def precursor_qvalue = VersionUtils.resolvePrecursorQvalue(params)` → `--qvalue ${precursor_qvalue}`
- `diann_msstats/main.nf`: same → `--qvalue_threshold ${precursor_qvalue}`

`VersionUtils` is auto-loaded from `lib/`; no import needed.

### Edge cases

- `diann_version` unset → falls back to `'1.8.1'` → `0.01`.
- Malformed version → `VersionUtils.compare` treats bad components as `0`, no exception.
- `precursor_qvalue` explicitly `0`/`0.0` → treated as override, used as-is.

---

## Change 2 — Disable fast-mode calibration flags

### Problem

The preliminary-analysis (calibration) step injects, **on by default**:

- `nextflow.config`: `performance_mode = true` → `--min-corr 2 --corr-diff 1 --time-corr-only`
- applied in `modules/local/diann/preliminary_analysis/main.nf`

Vadim: `--min-corr 2` and `--corr-diff 1 --time-corr-only` **may be really
harmful to IDs**. `--quick-mass-acc` is fine (only adds minor run-to-run
randomness vs fixed mass accuracies).

### Design

- `nextflow.config`: flip the default to `performance_mode = false`. Keep the
  param so users can still opt in to the speed flags explicitly. Update the
  comment to note these reduce IDs and are off by default per DIA-NN guidance.
- `quick_mass_acc`: **unchanged** (stays `true`).
- No module logic change needed — `preliminary_analysis/main.nf` already gates the
  flags on `params.performance_mode`; flipping the default disables them.
- `nextflow_schema.json` / `docs/parameters.md`: update the `performance_mode`
  default + description.

---

## Testing / validation

Current state to be aware of: **no default test profile pins DIA-NN 2.5.0** —
`test_dia`/`test_latest_dia` resolve to ≤ 2.2.0 and `test_dda` to 2.3.2, all of
which map to `0.01` under the new rule. So existing CI does **not** exercise the
`>= 2.5 → 0.05` path; that must be added.

- **1.8.1 (covered):** `test_dia` must still emit `--qvalue 0.01` and must **not**
  emit `--min-corr/--corr-diff/--time-corr-only`. Verify via the `.command.sh`
  of `preliminary_analysis` and `final_quantification`.
- **2.5.0 (new coverage needed):** the repo has `conf/diann_versions/v2_5_0.config`
  and a "Latest" CI matrix slot. Add explicit coverage of the 0.05 path — either
  (a) a CI/test invocation at 2.5.0 (e.g. `-c conf/diann_versions/v2_5_0.config`)
  asserting `--qvalue 0.05`, or (b) bump the "Latest" matrix entry to 2.5.0.
  Decide which during planning.
- **Override guarantee (must test):** run a 2.5.0 path **with** an explicit
  `--precursor_qvalue 0.02` and assert the DIA-NN command line shows
  `--qvalue 0.02` (not the `0.05` version default). Conversely a 1.8.1 path with
  `--precursor_qvalue 0.05` must show `--qvalue 0.05` (not `0.01`). Also confirm
  that omitting the param leaves no schema-injected value (i.e. the auto default
  applies) — e.g. via the resolved value in `.command.sh`.
- **Resolver logic:** the harness is nf-test (no Groovy unit harness for `lib/`),
  so a standalone unit test for `resolvePrecursorQvalue` is awkward. Treat the
  integration paths above as the primary guard; document the expected mapping
  (1.8.1/2.1/2.2/2.3.2→0.01, 2.5+→0.05, explicit override wins,
  null/blank version→0.01) in the PR.
- **Benchmark (per Vadim/reviewer request):** compare 1.8.1 vs 2.5 on
  representative data at **protein-group level**; if newer shows no clear PG-level
  advantage, capture and share the DIA-NN logs. Validation on data, not a code change.

## Files touched

- `nextflow.config` — `precursor_qvalue` default → null; `performance_mode` default → false (+ comments)
- `lib/VersionUtils.groovy` — add `resolvePrecursorQvalue`
- `modules/local/diann/final_quantification/main.nf` — resolve `--qvalue`
- `modules/local/diann/diann_msstats/main.nf` — resolve `--qvalue_threshold`
- `nextflow_schema.json` — `precursor_qvalue` (type/default/description), `performance_mode` (default/description)
- `docs/parameters.md` — both params
- `CHANGELOG.md` — note both default changes
