------

## What is this?

This web app runs the pipeline to estimate the **G**enetic diversity **In**dicators from a **Ko**botoolbox form. Its purpose is to estimate the genetic diversity indicators by country and high-quality reports based on data that was captured in Kobo, using the template available at the [Guideline materials and documentation for the Genetic Diversity Indicators of the monitoring framework for the Kunming-Montreal Global Biodiversity Framework](https://ccgenetics.github.io/guidelines-genetic-diversity-indicators/docs/5_Data_collection/Web_tool.html).

**Target users:** practitioners or research teams that willing to assess the genetic diversity indicators by themselves and examine the results without having to process the data by themselves in R (due to lack of time, programming capacities, etc).

**Background:** Kobotoolbox is a tool for data collection in webforms. We used it in the pilot [multicountry assessment of the genetic diversity indicators](https://onlinelibrary.wiley.com/doi/full/10.1111/ele.14461). In order to estimate the indicators, first the output of Kobo needs to be reformatted in tables to estimate the indicators for each country or species. This is currently done by a series of R functions that were previously developed, but running them requires knowledge of R and time, resources that are commonly lacking. So we made this app to do it for you :)

## How to use this app

The app runs a total of four steps. Each step needs at least one input file, and produces a series of output files needed for the subsequent step. It also produces a detailed report for each step.

You can run all steps one after another. After each step runs, you will be able to download the output data and the report, and then continue to the next step. You can also run only one step, assuming that you have the input data needed for it.

* **Step 1 Raw data quality test:** performs a quality check on the data from raw output exported from Kobo.
* **Step 2 Re-format and extract indicators data**: re-formats the data from the kobo-output so that data can be used  estimate the indicators. There is an output for each of the 3 indicators (Ne 500, PM, DNA-based monitoring).
* **Step 3 Estimate indicators:** estimates the Genetid Diversity Indiciators for each of the assessments (e.g. for each species assessed). The output includes the Ne 500 and PM indicator value per record along with kew metadata in a single large table.
* **Step 4 Country report:** creates a report including plots and simple statistics summarizing the indicator values.

To use the app, simply click on each of the boxes detailing each step below, and follow instructions.

------
