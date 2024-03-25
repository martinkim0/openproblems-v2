# Spatial decomposition


Estimation of cell type proportions per spot in 2D space from spatial
transcriptomic data coupled with corresponding single-cell data

Path:
[`src/tasks/spatial_decomposition`](https://github.com/openproblems-bio/openproblems-v2/tree/main/src/tasks/spatial_decomposition)

## Motivation

Spatial decomposition (also often referred to as Spatial deconvolution)
is applicable to spatial transcriptomics data where the transcription
profile of each capture location (spot, voxel, bead, etc.) do not share
a bijective relationship with the cells in the tissue, i.e., multiple
cells may contribute to the same capture location. The task of spatial
decomposition then refers to estimating the composition of cell
types/states that are present at each capture location. The cell
type/states estimates are presented as proportion values, representing
the proportion of the cells at each capture location that belong to a
given cell type.

## Description

We distinguish between *reference-based* decomposition and *de novo*
decomposition, where the former leverage external data (e.g., scRNA-seq
or scNuc-seq) to guide the inference process, while the latter only work
with the spatial data. We require that all datasets have an associated
reference single cell data set, but methods are free to ignore this
information. Due to the lack of real datasets with the necessary
ground-truth, this task makes use of a simulated dataset generated by
creating cell-aggregates by sampling from a Dirichlet distribution. The
ground-truth dataset consists of the spatial expression matrix, XY
coordinates of the spots, true cell-type proportions for each spot, and
the reference single-cell data (from which cell aggregated were
simulated).

## Authors & contributors

| name             | roles              |
|:-----------------|:-------------------|
| Giovanni Palla   | author, maintainer |
| Scott Gigante    | author             |
| Sai Nirmayi Yasa | author             |

## API

``` mermaid
flowchart LR
  file_common_dataset("Common Dataset")
  comp_process_dataset[/"Data processor"/]
  file_single_cell("Single cell data")
  file_spatial_masked("Spatial masked")
  file_solution("Solution")
  comp_control_method[/"Control method"/]
  comp_method[/"Method"/]
  comp_metric[/"Metric"/]
  file_output("Output")
  file_score("Score")
  file_common_dataset---comp_process_dataset
  comp_process_dataset-->file_single_cell
  comp_process_dataset-->file_spatial_masked
  comp_process_dataset-->file_solution
  file_single_cell---comp_control_method
  file_single_cell---comp_method
  file_spatial_masked---comp_control_method
  file_spatial_masked---comp_method
  file_solution---comp_control_method
  file_solution---comp_metric
  comp_control_method-->file_output
  comp_method-->file_output
  comp_metric-->file_score
  file_output---comp_metric
```

## File format: Common Dataset

A subset of the common dataset.

Example file:
`resources_test/spatial_decomposition/cxg_mouse_pancreas_atlas/dataset_simulated.h5ad`

Format:

<div class="small">

    AnnData object
     obs: 'cell_type', 'batch'
     var: 'hvg', 'hvg_score'
     obsm: 'X_pca', 'coordinates', 'proportions_true'
     layers: 'counts'
     uns: 'cell_type_names', 'dataset_id', 'dataset_name', 'dataset_url', 'dataset_reference', 'dataset_summary', 'dataset_description', 'dataset_organism'

</div>

Slot description:

<div class="small">

| Slot                         | Type      | Description                                                                                                         |
|:-----------------------------|:----------|:--------------------------------------------------------------------------------------------------------------------|
| `obs["cell_type"]`           | `string`  | Cell type label IDs.                                                                                                |
| `obs["batch"]`               | `string`  | A batch identifier. This label is very context-dependent and may be a combination of the tissue, assay, donor, etc. |
| `var["hvg"]`                 | `boolean` | Whether or not the feature is considered to be a ‘highly variable gene’.                                            |
| `var["hvg_score"]`           | `integer` | A ranking of the features by hvg.                                                                                   |
| `obsm["X_pca"]`              | `double`  | The resulting PCA embedding.                                                                                        |
| `obsm["coordinates"]`        | `double`  | (*Optional*) XY coordinates for each spot.                                                                          |
| `obsm["proportions_true"]`   | `double`  | (*Optional*) True cell type proportions for each spot.                                                              |
| `layers["counts"]`           | `integer` | Raw counts.                                                                                                         |
| `uns["cell_type_names"]`     | `string`  | (*Optional*) Cell type names corresponding to values in `cell_type`.                                                |
| `uns["dataset_id"]`          | `string`  | A unique identifier for the dataset.                                                                                |
| `uns["dataset_name"]`        | `string`  | Nicely formatted name.                                                                                              |
| `uns["dataset_url"]`         | `string`  | (*Optional*) Link to the original source of the dataset.                                                            |
| `uns["dataset_reference"]`   | `string`  | (*Optional*) Bibtex reference of the paper in which the dataset was published.                                      |
| `uns["dataset_summary"]`     | `string`  | Short description of the dataset.                                                                                   |
| `uns["dataset_description"]` | `string`  | Long description of the dataset.                                                                                    |
| `uns["dataset_organism"]`    | `string`  | (*Optional*) The organism of the sample in the dataset.                                                             |

</div>

## Component type: Data processor

Path:
[`src/spatial_decomposition`](https://github.com/openproblems-bio/openproblems-v2/tree/main/src/spatial_decomposition)

A spatial decomposition dataset processor.

Arguments:

<div class="small">

| Name                      | Type   | Description                                                                                                                                                     |
|:--------------------------|:-------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `--input`                 | `file` | A subset of the common dataset.                                                                                                                                 |
| `--output_single_cell`    | `file` | (*Output*) The single-cell data file used as reference for the spatial data.                                                                                    |
| `--output_spatial_masked` | `file` | (*Output*) The spatial data file containing transcription profiles for each capture location, without cell-type proportions for each spot.                      |
| `--output_solution`       | `file` | (*Output*) The spatial data file containing transcription profiles for each capture location, with true cell-type proportions for each spot / capture location. |

</div>

## File format: Single cell data

The single-cell data file used as reference for the spatial data

Example file:
`resources_test/spatial_decomposition/cxg_mouse_pancreas_atlas/single_cell_ref.h5ad`

Format:

<div class="small">

    AnnData object
     obs: 'cell_type', 'batch'
     layers: 'counts'
     uns: 'cell_type_names', 'dataset_id'

</div>

Slot description:

<div class="small">

| Slot                     | Type      | Description                                                                                                                      |
|:-------------------------|:----------|:---------------------------------------------------------------------------------------------------------------------------------|
| `obs["cell_type"]`       | `string`  | Cell type label IDs.                                                                                                             |
| `obs["batch"]`           | `string`  | (*Optional*) A batch identifier. This label is very context-dependent and may be a combination of the tissue, assay, donor, etc. |
| `layers["counts"]`       | `integer` | Raw counts.                                                                                                                      |
| `uns["cell_type_names"]` | `string`  | Cell type names corresponding to values in `cell_type`.                                                                          |
| `uns["dataset_id"]`      | `string`  | A unique identifier for the dataset.                                                                                             |

</div>

## File format: Spatial masked

The spatial data file containing transcription profiles for each capture
location, without cell-type proportions for each spot.

Example file:
`resources_test/spatial_decomposition/cxg_mouse_pancreas_atlas/spatial_masked.h5ad`

Format:

<div class="small">

    AnnData object
     obsm: 'coordinates'
     layers: 'counts'
     uns: 'cell_type_names', 'dataset_id'

</div>

Slot description:

<div class="small">

| Slot                     | Type      | Description                                                               |
|:-------------------------|:----------|:--------------------------------------------------------------------------|
| `obsm["coordinates"]`    | `double`  | XY coordinates for each spot.                                             |
| `layers["counts"]`       | `integer` | Raw counts.                                                               |
| `uns["cell_type_names"]` | `string`  | Cell type names corresponding to columns of `proportions_pred` in output. |
| `uns["dataset_id"]`      | `string`  | A unique identifier for the dataset.                                      |

</div>

## File format: Solution

The spatial data file containing transcription profiles for each capture
location, with true cell-type proportions for each spot / capture
location.

Example file:
`resources_test/spatial_decomposition/cxg_mouse_pancreas_atlas/solution.h5ad`

Format:

<div class="small">

    AnnData object
     obsm: 'coordinates', 'proportions_true'
     layers: 'counts'
     uns: 'cell_type_names', 'dataset_id'

</div>

Slot description:

<div class="small">

| Slot                       | Type      | Description                                                |
|:---------------------------|:----------|:-----------------------------------------------------------|
| `obsm["coordinates"]`      | `double`  | XY coordinates for each spot.                              |
| `obsm["proportions_true"]` | `double`  | True cell type proportions for each spot.                  |
| `layers["counts"]`         | `integer` | Raw counts.                                                |
| `uns["cell_type_names"]`   | `string`  | Cell type names corresponding to columns of `proportions`. |
| `uns["dataset_id"]`        | `string`  | A unique identifier for the dataset.                       |

</div>

## Component type: Control method

Path:
[`src/spatial_decomposition/control_methods`](https://github.com/openproblems-bio/openproblems-v2/tree/main/src/spatial_decomposition/control_methods)

Quality control methods for verifying the pipeline.

Arguments:

<div class="small">

| Name                     | Type   | Description                                                                                                                                          |
|:-------------------------|:-------|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `--input_single_cell`    | `file` | The single-cell data file used as reference for the spatial data.                                                                                    |
| `--input_spatial_masked` | `file` | The spatial data file containing transcription profiles for each capture location, without cell-type proportions for each spot.                      |
| `--input_solution`       | `file` | The spatial data file containing transcription profiles for each capture location, with true cell-type proportions for each spot / capture location. |
| `--output`               | `file` | (*Output*) Spatial data with estimated proportions.                                                                                                  |

</div>

## Component type: Method

Path:
[`src/spatial_decomposition/methods`](https://github.com/openproblems-bio/openproblems-v2/tree/main/src/spatial_decomposition/methods)

A spatial composition method.

Arguments:

<div class="small">

| Name                     | Type   | Description                                                                                                                     |
|:-------------------------|:-------|:--------------------------------------------------------------------------------------------------------------------------------|
| `--input_single_cell`    | `file` | The single-cell data file used as reference for the spatial data.                                                               |
| `--input_spatial_masked` | `file` | The spatial data file containing transcription profiles for each capture location, without cell-type proportions for each spot. |
| `--output`               | `file` | (*Output*) Spatial data with estimated proportions.                                                                             |

</div>

## Component type: Metric

Path:
[`src/spatial_decomposition/metrics`](https://github.com/openproblems-bio/openproblems-v2/tree/main/src/spatial_decomposition/metrics)

A spatial decomposition metric.

Arguments:

<div class="small">

| Name               | Type   | Description                                                                                                                                          |
|:-------------------|:-------|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `--input_method`   | `file` | Spatial data with estimated proportions.                                                                                                             |
| `--input_solution` | `file` | The spatial data file containing transcription profiles for each capture location, with true cell-type proportions for each spot / capture location. |
| `--output`         | `file` | (*Output*) Metric score file.                                                                                                                        |

</div>

## File format: Output

Spatial data with estimated proportions.

Example file:
`resources_test/spatial_decomposition/cxg_mouse_pancreas_atlas/output.h5ad`

Description:

Spatial data file with estimated cell type proportions.

Format:

<div class="small">

    AnnData object
     obsm: 'coordinates', 'proportions_pred'
     layers: 'counts'
     uns: 'cell_type_names', 'dataset_id', 'method_id'

</div>

Slot description:

<div class="small">

| Slot                       | Type      | Description                                                |
|:---------------------------|:----------|:-----------------------------------------------------------|
| `obsm["coordinates"]`      | `double`  | XY coordinates for each spot.                              |
| `obsm["proportions_pred"]` | `double`  | Estimated cell type proportions for each spot.             |
| `layers["counts"]`         | `integer` | Raw counts.                                                |
| `uns["cell_type_names"]`   | `string`  | Cell type names corresponding to columns of `proportions`. |
| `uns["dataset_id"]`        | `string`  | A unique identifier for the dataset.                       |
| `uns["method_id"]`         | `string`  | A unique identifier for the method.                        |

</div>

## File format: Score

Metric score file.

Example file:
`resources_test/spatial_decomposition/cxg_mouse_pancreas_atlas/score.h5ad`

Format:

<div class="small">

    AnnData object
     uns: 'dataset_id', 'method_id', 'metric_ids', 'metric_values'

</div>

Slot description:

<div class="small">

| Slot                   | Type     | Description                                                                                  |
|:-----------------------|:---------|:---------------------------------------------------------------------------------------------|
| `uns["dataset_id"]`    | `string` | A unique identifier for the dataset.                                                         |
| `uns["method_id"]`     | `string` | A unique identifier for the method.                                                          |
| `uns["metric_ids"]`    | `string` | One or more unique metric identifiers.                                                       |
| `uns["metric_values"]` | `double` | The metric values obtained for the given prediction. Must be of same length as ‘metric_ids’. |

</div>
