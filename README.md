# MP lookup postcode search

## Introduction 

This R Shiny app seeks to expand the functionality of [DfE's MP lookup](https://github.com/dfe-analytical-services/mp-lookup). It links the MP lookup with the [Postcode to Westminster Parliamentary Constituencies Lookup](https://geoportal.statistics.gov.uk/datasets/6f2f35a9a0b94e7e949eeba7785911d4/about) from the [Open Geography Portal](https://geoportal.statistics.gov.uk/). This allows users to search postcodes to retrieve up-to-date information on the MP of the Constituency that the postcode is in.

This application is not yet deployed.

## Requirements

The following requirements are necessary for running the application yourself or contributing to it.

### i. Software requirements (for running locally)

- Installation of R Studio 2024.04.2+764 "Chocolate Cosmos" or higher

- Installation of R 4.4.1 or higher

- Installation of RTools44 or higher

### ii. Programming skills required (for editing or troubleshooting)

- R at an intermediate level, [DfE R learning resources](https://dfe-analytical-services.github.io/analysts-guide/learning-development/r.html)

- Particularly [R Shiny](https://shiny.rstudio.com/)

### iii. Access requirements

To contribute to the repo you will need to be given access to create new branches, commit and push / pull, contact explore.statistics@education.gov.uk for this.

Data is stored in a [Pins](https://pins.rstudio.com/) board on a databricks volume, to access this (and run the app) locally you will need to set the following variables locally:
- DATABRICKS_HOST
- DATABRICKS_TOKEN

[usethis](https://usethis.r-lib.org/) provides the `usethis::edit_r_environ()` funciton that gives a handy way to set you local environment variables for R. More guidance on finding your HOST and TOKEN from databricks can be found on the [internal POSITCONNECT guidance](https://rsconnect/rsc/posit-connect-guidance/_book/databricks-connections.html).

Note that a SQL Warehouse is not required - Pins effectively works via an API, so just having the host and token set is sufficient for the connection to be made.

## Running the app locally

1. Clone or download the repo. 

2. Open the folder in Positron / R Studio.

3. Set up your environment variables (DATABRICKS_HOST / DATABRICKS_TOKEN).

4. Run `renv::restore()` to install dependencies.

5. Run `shiny::runApp()` to run the app.

### Packages

Package control is handled using renv. As in the steps above, you will need to run `renv::restore()` if this is your first time using the project.

Whenever you add new packages, make sure to use `renv::snapshot()` to record them in the `renv.lock` file.

### Tests

You should run `shinytest2::test_app()` regularly to check that the tests are passing against the code you are working on. The tests are not currently running on GitHub Actions as they need access to the data, which can only happen from internal servers. In future we should make local test data available for tests to use so we can add GitHub actions runs of the automated tests back to this project.

## How to contribute

If you spot a bug or feature you want to report, please check first that it has not been reported as an [issue](https://github.com/dfe-analytical-services/mp-lookup-postcode-search/issues) already.

If no issue is open for your bug or feature, please [open a new one](https://github.com/dfe-analytical-services/mp-lookup-postcode-search/issues/new)

### Making suggestions

You can also use the "Issues" tab in GitHub to suggest new features, changes or additions. Include as much detail on why you're making the suggestion and any thinking towards a solution that you have already done.

## Contact

The best way to get in contact would be to [raise an issue](https://github.com/dfe-analytical-services/mp-lookup-postcode-search/issues) on this repository.
