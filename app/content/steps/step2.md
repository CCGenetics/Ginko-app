-----

## Step 2 - Processing clean data to extract indicator data

This steps performs the following:

1) it re-formats the data as outputed by Kobo to the shape needed to calculate each of the genetic diversity indicators. For example, in the Kobo output each species assessment is a single row, with population data in different columns, but to estimate the Ne indicator it is needed to have data of each population as a row. This script does that format transformation for you.

2) and transforms Nc to Ne based on a custom Nc:Ne ratio.

Notice that at this stage the **indicator values are not calculated**. This script only re-formats the data from the kobo-output so that you can use these data to estimate the indicators by yourself outside R (e.g. in Excel or other software), or continue to step 3 if you want to use the R functions and standard analyses of this repository.

The input is the "clean kobo output" that was first cleaned in step 1. The output are the indicators data ready to be used to estimate the indicators.

* `indNe_data.csv` file: data needed to estimate the Ne 500 indicator.  Each population is a row and the population size data (either Ne or Nc) is provided in different columns. 

* `indPM_data.csv` file: data needed to estimate the PM indicator. Each row is a taxon of a single assessment, and the number of extant and extinct populations are provided.

* `indDNAbased_data` file: data needed to estimate the genetic monitoring indicator (number of species in which genetic diversity has been or is being monitored using DNA-based methods). Each row is a taxon.

* `metadata.csv` file: metadata for taxa and indicators, in some cases creating new useful variables, like taxon name (joining Genus, species, etc) and if the taxon was assessed only a single time or multiple times

### Important note on transforming Nc to Ne data:

In the Kobo form, Ne and Nc data are collected as follows: 

* **Ne (effective population size) from genetic analyses**, ie by software like NeEstimator or Gone. The estimate and its lower an upper limits are stored as numbers in the columns `Ne`, `NeLower`, `NeUpper`. These columns are not modified during processing.

* **Nc (number of mature individuals) from point estimates**, that is quantitative data with or without confidence intervals. The estimate and its lower an upper limits, if available, are stored as numbers in the columns `NcPoint`, `NcLower`, `NcUpper`.

* **Nc (number of mature individuals) from quantitative range or qualitative data**, these are the ranges that in the kobo form show options like "<5,000 by much" or "< 5,000 but not by much (tens or a few hundred less)". The estimate is stored as text in the column `NcRange`. 

This steps uses the function `transform_to_Ne()` ([see it here](https://github.com/CCGenetics/Ginko-Rfun/blob/main/transform_to_Ne.R)) to transform Nc estimates and their lower an upper estimates to Ne based on the Nc:Ne ratio the user decides.

For `NcPoint`, `NcLower`, `NcUpper` columns (Nc from point estimates) Nc is transformed to Ne done by multiplying them for the desired ratio. 

For `NcRange`columns (Nc from quantitative range or qualitative data) the range options (text) are first translated to numbers following this rule:

* "more_5000_bymuch" to 10000
* "more_5000" to 5500
* "less_5000_bymuch" to 500
* "less_5000" to 4050
* "range_includes_5000" to 5001

This is stored in the new column `Nc_from_range`. And then, to transform Nc to Ne it is multiplied for the desired ratio.

Regardless if the Nc data was NcPoint or NcRange, after transforming it to Ne it is stored in the column `Ne_from_Nc`. Notice that the column `NcType` (part of the Koboform original variables) states if Nc data came from NcPoint or NcRange. If the type as NcPoint and there were lower and upper intervals, they are also transformed to Ne and stored in the columns `NeLower_from_Nc`, `NeUpper_from_Nc`.

Finally, a new column `Ne_combined` is created combining data from Ne genetic estimates, with the Ne from transforming Nc using the ratio. For this, if both Ne from genetic data and from transforming Nc exist, the Ne from genetic data is given preference. 

For transparency, the column `Ne_calculated_from` specifies for each population were the data to estimate Ne came from. Options are:  "genetic data", "NcPoint ratio", and "NcRange ratio", as explained above.


-----
