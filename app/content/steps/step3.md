-----

## Step 3 - Estimate indicators

Estimates the Genetid Diversity Indiciators for each of the assessments (e.g. for each species assessed). The output includes the Ne 500 and PM indicator value per record along with kew metadata in a single large table.

#### Ne 500 indicator
The Ne 500 indicator es estimated by dividing “the number of populations whithin a species with Ne > 500” over “the number of populations within a species with data to estimate Ne”.

Here the indicator is estimated not by taxon but by X_uuid (unique record of a taxon), because a single taxon could be assessed by different countries or more than once with different parameters).

This is done with the function `estimate_indicatorNe()` ([see it here](https://github.com/CCGenetics/Ginko-Rfun/blob/main/estimate_indicatorNe.R)).

#### PM indicator

The Proportion of Maintained populations (PM indicator) is the he proportion of populations within species which are maintained. This can be estimated based on the `n_extant_populations` and `n_extinct_populations`, as follows: 

n_extant_populations / n_extant_populations + n_extinct_populations.

#### DNA-based genetic monitoring indicator

This indicator refers to the number (count) of taxa by country in which genetic monitoring based on DNA-methods is occurring. This is stored in the variable ´temp_gen_monitoring´ as a “yes/no” answer for each taxon, so to estimate the indicator, we only need to count how many said “yes”, keeping only one of the records when the taxon was multiassessed.

#### Output:

* A .csv file (called `indicators_full.csv`) The PM and Ne 500 indicators and the metadata in a single large table, in which each row is a taxon assessed. 
* A report of the step in html format, where you can also see the header of the indicator values

-----
