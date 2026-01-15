# 00 — Upload data

Upload the raw CSV exported from KoboToolbox.

## What happens next
- The file is copied into the project run directory as `00_raw_data.csv`.
- Step 1 will run a quality check and generate:
  - an HTML report,
  - `kobo_output_tocheck.csv`,
  - `kobo_output_clean.csv`.

## Tips
- Prefer UTF-8 encoded CSV.
- Do not edit column names in the export.
