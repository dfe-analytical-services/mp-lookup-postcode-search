# Pipelines

Data refresh notebooks that keep the app's pin data up to date. **These notebooks are designed to run on Databricks compute, not locally.** The Shiny app itself only reads the resulting pin files — it does not execute any pipeline code.

## What the pipeline does

The pipeline writes two versioned [pins](https://pins.rstudio.com/) (parquet files) to a Unity Catalog Volume at:

```
/Volumes/catalog_40_copper_statistics_services/postcode_mp/pins
```

| Notebook | Pin name | Source | Summary |
| --- | --- | --- | --- |
| `update-postcode` | `postcode_lookup` | `catalog_10_gold.conformed_dimensions.dim_postcode_geography_latest` (Delta table in Unity Catalog) | Maps every postcode to its parliamentary constituency code |
| `update-mp` | `constituency_data` | [mp_lookup.csv on GitHub](https://github.com/dfe-analytical-services/mp-lookup/blob/main/mp_lookup.csv) | MP and constituency reference data |

Both notebooks share common setup via `_shared_setup`, which loads packages, authenticates against the workspace, connects to the pins board, and provides helper functions.

Each notebook includes **change detection** so that it skips the write entirely when the source data has not changed (Delta table version for postcodes, GitHub commit SHA + content hash for MP data). This keeps job runs fast and avoids unnecessary pin versions.

## Execution order

`update-postcode` runs first, then `update-mp` (which depends on it). This order is enforced by the job definition in `databricks.yml`.

## Accessing the pipeline in Databricks

The pipeline is deployed as a scheduled Databricks job called **"Update MP & Postcode Pins"**, defined in `databricks.yml` at the project root. It runs daily at 08:00 Europe/London on an existing cluster.

To find the job in the workspace:

1. Open the **Jobs** page in the Databricks sidebar.
2. Search for *"Update MP & Postcode Pins"*.
3. From there you can view run history, trigger a manual run, or inspect logs.

You can also run the notebooks interactively by opening them in the Databricks notebook editor and attaching to any R-capable cluster.

## Updating and redeploying the bundle

The project uses [Databricks Asset Bundles (DABs)](https://docs.databricks.com/dev-tools/bundles/index.html). All job configuration lives in `databricks.yml` in the project root.

### Making changes

1. Edit the notebook(s) or `databricks.yml` as needed.
2. Validate the bundle configuration:
   ```bash
   databricks bundle validate --target prod
   ```
3. Deploy to production:
   ```bash
   databricks bundle deploy --target prod
   ```
4. Optionally trigger a run to verify:
   ```bash
   databricks bundle run update_pins --target prod
   ```

### Cluster

Both tasks use one of Cam's clusters `0324-165928-8wjhg0qa`. If the cluster ID changes, update the `existing_cluster_id` field in `databricks.yml` and redeploy.
