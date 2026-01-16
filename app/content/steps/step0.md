------

## What is this?

This web app runs the pipeline to estimate the **G**enetic diversity **In**dicators from a **Ko**botoolbox form. Its purpose is to estimate the genetic diversity indicators by country and high-quality reports based on data that was captured in Kobo, using the template available at the [Guideline materials and documentation for the Genetic Diversity Indicators of the monitoring framework for the Kunming-Montreal Global Biodiversity Framework](https://ccgenetics.github.io/guidelines-genetic-diversity-indicators/docs/5_Data_collection/Web_tool.html).

**Target users:** practitioners or research teams that willing to assess the genetic diversity indicators by themselves and examine the results without having to process the data by themselves in R (due to lack of time, programming capacities, etc).

**Background:** Kobotoolbox is a tool for data collection in webforms. We used it in the pilot [multicountry assessment of the genetic diversity indicators](https://onlinelibrary.wiley.com/doi/full/10.1111/ele.14461). In order to estimate the indicators, first the output of Kobo needs to be reformatted in tables to estimate the indicators for each country or species. This is currently done by a series of R functions that were previously developed, but running them requires knowledge of R and time, resources that are commonly lacking. So we made this app to do it for you :)

## Ready? Upload data!

Upload the **raw output exported from KoboToolbox in .csv format** as downloaded using [these instructions](https://ccgenetics.github.io/guidelines-genetic-diversity-indicators/docs/5_Data_collection/Kobo_toolbox_help.html). 

Tips:
- The file will be exported using UTF-8 encoded CSV.
- Do not edit column names in the export.

### What happens next
- The file is copied into the project run directory as `00_raw_data.csv`.
- Step 1 will run a quality check and generate:
  - an HTML report,
  - `kobo_output_tocheck.csv`,
  - `kobo_output_clean.csv`.



------
