# grass_valley

<!-- badges: start -->
[![DOI](https://zenodo.org/badge/644078765.svg)](https://zenodo.org/doi/10.5281/zenodo.11661269)
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC_BY_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)
[![Static Badge](https://img.shields.io/badge/Quarto-Paper-74AADB?style=social&logo=Quarto)](https://quarto.org)
<!-- badges: end -->

This repository contains data and code for the paper:

> Kenneth B. Vernon 
> [![](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0003-0098-5092),
> Kate E. Margargal
> [![](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0002-7444-7847),
> Paul Allgaier
> [![](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0001-9159-8156),
> David Zeanah
> [![](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0002-1944-4555),
> D. Craig Young
> [![](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0002-0316-310X),
> Robert G. Elston
> [![](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0002-2213-2368),
> Simon Brewer
> [![](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0002-6810-1911),
> and Brian F. Codding
> [![](https://orcid.org/sites/default/files/images/orcid_16x16.png)](https://orcid.org/0000-0001-7977-8568)
> (). Explaining PaleoIndian settlement in the Intermountain West with comparative machine learning.
> *Journal of Archaeological Science*.

**Preprint**: [manuscript.pdf](/manuscript/manuscript.pdf)\
**Supplement**:
[analysis.html](https://kbvernon.github.io/grass-valley/R/analysis.html)

## Contents

📂 [\_extensions](/_extensions) has Quarto extension for compiling manuscript\
📂 [data](/data) required for reproducing analysis and figures\
  ⊢ 🌎 grass-valley.gpkg is a GeoPackage database with all necessary data\
model\
  ⊢ 📈 western-fremont-model.Rds is the final model\
📂 [figures](/figures) contains all figures included in the paper\
📂 [manuscript](/manuscript) contains the pre-print\
  ⊢ 📄 [manuscript.qmd](/manuscript/manuscript.qmd)\
  ⊢ 📄 [manuscript.pdf](/manuscript/manuscript.pdf)\
📂 [R](/R) code for preparing data and conducting analysis, including\
  ⊢ 📄 [analysis.qmd](/R/analysis.qmd) is the primary analysis,\
  ⊢ 📄 [data-wrangling.R](/R/data-wrangling.R),\

## 💾 Data availability

Unfortunately, the locations of archaeological sites in the US count as
sensitive data, so we cannot simply share them here. If you would like to use
any of these data, you will need to get permission from the State Historic
Preservation Office in Nevada.

## 📈 Replicate analysis

Assuming you had access to the data in `grass-valley.gpkg`, you could
re-run all of the data preparation and analysis like this:

``` r
# install R dependencies
if (!require(renv)) install.packages("renv")
renv::restore()

library(quarto)

# needs to be run in this order
file.path("R", "data-wrangling.R") |> source()
file.path("R", "analysis.qmd") |> quarto_render()

# if you have a hankerin' to compile the manuscript
# you can do that like so:
file.path("manuscript", "manuscript.qmd") |> quarto_render()
```

## License

**Text and figures:** [CC-BY-4.0](http://creativecommons.org/licenses/by/4.0/)

**Code:** [MIT](LICENSE.md)

**Data:** not available.