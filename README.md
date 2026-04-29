# efish_em_ELL

Code repository accompanying:

**Perks, Petkova, Muller et al. (2025). "Connectome analysis of a recurrent multi-layer network for continual learning in electric fish."**

This repository contains Jupyter notebooks and Python utilities for processing and analyzing data from the electrosensory lobe (ELL) connectome of *Gnathonemus petersii* (African pulse-type electric fish).

**License:** MIT (code). The companion data archive `EM_data_published/` is released under CC-BY-4.0.

---

## Contents

- [Data Download](#data-download)
- [External Tools and Background](#external-tools-and-background)
- [Environment Setup](#environment-setup)
- [Setup and Launch](#setup-and-launch)
- [Notebook Guide](#notebook-guide)
- [Full Pipeline Workflow](#full-pipeline-workflow)
- [Repository Structure](#repository-structure)
- [Troubleshooting](#troubleshooting)

---

## Data Download

The analysis data (`EM_data_published/`, ~12.5 GB) is hosted separately from this repository due to file size constraints.

**Download from:** `[DATA_REPOSITORY_URL]`  *(placeholder — DOI will be added upon publication)*

After downloading and extracting, place the `EM_data_published/` folder **as a sibling** to this cloned repository, so your directory structure looks like:

```
your_directory/
├── EM_data_published/      ← downloaded data archive
└── efish_em_ELL/           ← this GitHub repository
```

### Expected contents of `EM_data_published/`

```
EM_data_published/
├── EM_data_published_CONTENTS.md          ← per-file description of the archive
├── reconstructions_published/             ← eCREST .json cell graph files
│   └── annotation-spines/
├── data_processed_published/              ← processed CSVs created and then used by analysis notebooks
│   ├── df_type_auto_typed.csv
│   ├── df_postsyn.csv
│   ├── df_presyn.csv
│   ├── df_spine_counts.csv
│   ├── MG_partial-cat.csv
│   ├── layer-molecular_annotation.json
│   └── morphology_cat/
├── data_VAST/
│   ├── iso_thumbnails_mSEM/               ← isotropic EM PNG stacks (used by Subvolume_dense-set.ipynb)
│   ├── matlab-helper-scripts/             ← MATLAB helpers that produced actual_coords_isotropic.mat (provenance)
│   └── volume_subsample_sg-mg-out_ratio/  ← subvolume CSVs + precomputed segmentation
├── ng_states/                             ← Neuroglancer state JSONs (template + 3 published views written by neuroglancer-demo-appspot.ipynb)
├── base-segs_query_published.csv          ← base-segment → voxel-location table (BigQuery export)
├── base-segs_query_published.parquet      ← same table in Parquet format
├── STATIC_published-reconstructions.json  ← base-segment → reconstructed-cell dictionary used to build the user-friendly static single-segment versions of each reconstruction
├── Mariela_bigquery_exports_agglo_v230111c_16_crest_proofreading_database.db
└── model/                                 ← all modeling data (consumed by Analyses_published.ipynb and ELL_net_model_paper/)
    ├── data_gc.mat
    ├── data_ell_net/                      ← input data for ELL_net_model_paper/ MATLAB simulations
    ├── fig5/
    ├── fig6/
    ├── figS4/
    ├── figS7/
    └── figS8/
```

**Modeling Data and Scripts**
Modeling data were obtained via custom MATLAB scripts (S. Muller) in the `ELL_net_model_paper/` subfolder of this repository. The processed outputs of those simulations are shipped in `EM_data_published/model/` so that `Analyses_published.ipynb` can reproduce the modeling figure panels without re-running the simulations. Each subfolder name matches the figure number in the final manuscript (`model/fig5/`, `model/fig6/`, `model/figS4/`, `model/figS7/`, `model/figS8/`); `.mat` filenames within these folders carry the names used at the time of manuscript submission.

See `EM_data_published/EM_data_published_CONTENTS.md` in the archive for a full per-file description.

---

## External Tools and Background

Several external tools were used in the data collection and processing pipeline. Brief descriptions and links are provided below for context.

### eCREST (Connectome Reconstruction and Exploration Simple Tool)

eCREST is a CLI-based Python interface built on top of [CREST](https://github.com/ashapsoncoe/CREST) (Connectome Reconstruction and Exploration Simple Tool; by Alex Shapson-Coe, @ashaponscoe). It enables users to (1) proofread biological objects and (2) identify individual network pathways, connections, and cell types in the [Neuroglancer](https://github.com/google/neuroglancer) interface.

eCREST was forked from CREST and modified into a CLI-based interface for utilizing CREST methods and makes extensive use of the Neuroglancer Python API. Additional methods were added to meet the needs of this specific project.

In this project, eCREST was used throughout the reconstruction phase to annotate synapses and soma, subcellular structures (axons, dendrites, etc), and cell types for all reconstructed neurons. The `eCREST_cli.py` module in this repository contains the `ecrest` class used during that process. The `eCREST_notebook.ipynb` documents the reconstruction workflow.

### VAST / VASTlite

[VASTlite](https://lichtman.rc.fas.harvard.edu/vast/) (Volume Annotation and Segmentation Tool, Harvard Lichtman Lab) is a tool for annotating and editing segments in large EM volumes.

In this project, VAST was used to combine and manually correct automated segment boundaries from the original EM database. `json_to_VASTskel.ipynb` converts eCREST `.json` reconstruction files into VAST-compatible skeleton format, which enables segment agglomeration in VAST for editing and quality control, and for mesh/image export. Exports from VAST were used directly in Extended Data Fig. 3C and imported to Blender for 3D rendering used in many figure panels.

**Fig 1D textured-box rendering (provenance).** Fig 1D shows an EM textured-box sample exported from VAST. The `.obj` and its PNG texture were post-processed to be compatible with the Blender renderings produced by `Blender_make_mesh.ipynb`:

1. **Exported** a textured box (`.obj` + `.png`) from VAST.
2. **Rotated the `.obj`** to match the axis orientation used by the Blender meshes generated in `Blender_make_mesh.ipynb` (which applies its own axis transform so that VAST-derived and CloudVolume-derived meshes share a coordinate frame).
3. **Rescaled coordinates** (same scale factor as `Blender_make_mesh.ipynb`) so that the model is spatially manageable inside Blender — at native nanometer units Blender cannot handle the vertex range robustly.
4. **Paired** the rotated/rescaled `.obj` with its PNG texture (matching filename root) and imported into Blender for rendering.

This preparation step is a one-off producing the Fig 1D asset; it is not required to reproduce any analysis and is not shipped as a notebook.

### Neuroglancer

[Neuroglancer](https://github.com/google/neuroglancer) is a WebGL-based viewer for volumetric data. It is capable of displaying arbitrary (non axis-aligned) cross-sectional views of volumetric data, as well as 3-D meshes and line-segment based models (skeletons).

In this project, Neuroglancer is utilized by eCREST/CREST for the proofreading workflow. Preset dataset states have been created for visualization via the linked Gallery.

### CloudVolume

[cloud-volume](https://github.com/seung-lab/cloud-volume) (Seung Lab) is a Python library for reading and writing volumetric datasets stored in [Neuroglancer Precomputed](https://github.com/google/neuroglancer/blob/master/src/datasource/precomputed/README.md) format.

In this project, CloudVolume is used in `morphology_cat_createDF.ipynb`, `Subvolume_dense-set`, and `SpineCounts.ipynb` to access segmentation meshes and skeletons in precomputed format.

> **Important:** CloudVolume does not support Windows. It must be run on Mac or Linux.

### Igneous / Precomputed volume

[Igneous](https://github.com/seung-lab/igneous) (Seung Lab) is a Python-based pipeline for processing large volumetric segmentations, including meshing, skeletonization, and downsampling.

The precomputed segmentation volume used for apical dendrite spine and length analysis (`data_VAST/volume_subsample_sg-mg-out_ratio/precomputed_subvolume-apical-revision/`) is **shipped directly in the data archive**, so end users of this code do not need to run Igneous themselves. It was generated from VAST composite segmentation via the following pipeline:

1. **VAST composite segmentation export** — segment agglomeration in VASTlite, exported as composite layer.
2. **Export to `.raw` binary** — via VASTlite's export function.
3. **Process `.raw` → HDF5 numpy array** — stack assembly and conversion into an HDF5 volume dataset.
4. **CloudVolume HDF5 → Precomputed format** — via `cloudvolume` ingestion tools.
5. **Igneous command-line pipeline** — `igneous mesh forge`, `igneous mesh merge`, `igneous skeleton forge` and `igneous skeleton merge` steps to produce meshes and skeletons to be served and queried from the precomputed directory.

To use the shipped precomputed volume, serve it locally with Igneous (port number for https serving can be specified per user choice, or the Igneous default can be used if no `--port` flag is passed):

```bash
cd EM_data_published/data_VAST/volume_subsample_sg-mg-out_ratio/
igneous view precomputed_subvolume-apical-revision --port 8001
```

`SpineCounts.ipynb` connects to this local server via `CloudVolume('precomputed://http://localhost:8001')`.

### Base-segment location table (Google BigQuery)

`json_to_VASTskel.ipynb` needs a table that maps each base segment ID in the reconstructions to a voxel-space location. At the time of publication, that table was produced by a one-shot BigQuery query against the `lcht-goog-connectomics.ell_roi450um_seg32fb16fb_220930.objinfo` table. The static result is **shipped directly in the data archive** as `EM_data_published/base-segs_query_published.{csv,parquet}`, so end users of this code do not need to run any BigQuery query themselves — the notebooks load the Parquet file directly via `pandas.read_parquet`.

For reproducibility, the table was generated by:

1. **Collect all base-segment IDs** across every published reconstruction by reading each eCREST `.json` file and unioning its `base_segments` sets.
2. **Authenticate to Google Cloud** (`gcloud auth application-default login`) on the `lcht-goog-connectomics` project.
3. **Batch-query BigQuery** in chunks of 10,000 segments against the `objinfo` table, selecting each segment's sample voxel `(x, y, z)`. Batching avoids BigQuery's query-size limit and intermittent connection errors.
4. **Concatenate batches** and persist as both CSV and Parquet for convenience (`base-segs_query_published.csv` and `.parquet`).

Re-running this pipeline requires the `google-cloud-bigquery` Python package and valid Google Cloud credentials for the `lcht-goog-connectomics` project, and is not part of the `efish_em_ELL` install tiers.

### Blender

[Blender](https://www.blender.org/) is open-source 3D creation software. `Blender_make_mesh.ipynb` uses [trimesh](https://trimesh.org/) to generate and downsample 3D mesh renderings (as `.obj` files) of reconstructed neurons for figure panels and supplemental videos.

---

## Environment Setup

The repository is installable via `pyproject.toml`. There are three install tiers — pick the one that matches which notebooks you plan to run.

> **About `static_solve.txt`:** this file is a provenance record of the exact conda environment used on the author's Mac to produce the published figures. It is **not** an installation target (many pins are osx-64 specific). Use the `pip install` commands below instead.

### Install tier 1 — base (Windows / macOS / Linux)

Runs the tier-1 analysis notebooks (`Analyses_published.ipynb`, `CellTyping.ipynb`, `Network-Build.ipynb`, `neuroglancer-demo-appspot.ipynb`) — sufficient to reproduce every published quantitative data panel from the shipped processed CSVs (does not include mesh creation for Blender renderings or live eCREST / CloudVolume operations).

```bash
conda create --name efish_em python=3.11
conda activate efish_em

git clone https://github.com/neurologic/efish_em_ELL.git
cd efish_em_ELL
pip install -e .
```

Python 3.9, 3.10, and 3.11 are all supported (see `pyproject.toml`); **3.11 is the version the published figures were generated under.**

### Install tier 2 — add live eCREST workflow (Windows / macOS / Linux)

Adds [`neuroglancer`](https://github.com/google/neuroglancer) and [`python-igraph`](https://python.igraph.org/). Needed for `eCREST_notebook.ipynb`.

```bash
pip install -e ".[ecrest]"
```

### Install tier 3 — add CloudVolume access to Precomputed volumes/meshes/skeletons (macOS / Linux only)

Adds [`cloud-volume`](https://github.com/seung-lab/cloud-volume), [`trimesh`](https://trimesh.org/), [`neuprint-python`](https://github.com/connectome-neuprint/neuprint-python), and [`igneous-pipeline`](https://github.com/seung-lab/igneous). Enables reading Neuroglancer Precomputed segmentation volumes, meshes, and skeletons. Needed for `SpineCounts.ipynb`, `Subvolume_dense-set.ipynb`, `morphology_cat_createDF.ipynb`, `json_to_VASTskel.ipynb`, and `Blender_make_mesh.ipynb`.

```bash
# macOS / Linux only — fresh environment recommended

conda create --name efish_em python=3.11
conda activate efish_em

pip install -e ".[cloudvolume]"
```

A single `pip install -e ".[cloudvolume]"` lets pip resolve the full tier-3 stack in one pass, so the `numpy<2.0` pin declared by the base package (which matches what `cloud-volume` needs transitively) is respected from the start.

If you also want the eCREST viewer (tier 2) in the same environment, the convenience bundle installs both extras at once:
```bash
pip install -e ".[all]"
```

> **Do not** run `pip install cloud-volume` by itself before installing the base package. A single-package `pip install` does not re-resolve the environment, so it pulls in the latest unconstrained `numpy` (2.x) and trips a resolver warning against the base package's `numpy<2.0` pin. If you have already hit this state, repair the env with:
> ```bash
> pip install "numpy<2.0"
> pip install -e ".[cloudvolume]"
> ```

### Windows users

Windows cannot run the CloudVolume tier (tier 3). The `EM_data_published/` archive ships the precomputed outputs of the CloudVolume notebooks (`df_spine_counts.csv`, `df_segments_assigned.csv`, `base-segs_query_published.parquet`), so Windows users can still reproduce every published figure via tier 1 (+ tier 2 if the live eCREST viewer is needed).

### Serving the apical dendrites precomputed volume (Mac/Linux, tier 3 only)

For `SpineCounts.ipynb`, the shipped precomputed mesh/skeleton directory must be served locally:

```bash
cd EM_data_published/data_VAST/volume_subsample_sg-mg-out_ratio/
igneous view precomputed_subvolume-apical-revision --port 8001
```

`SpineCounts.ipynb` connects via `CloudVolume('precomputed://http://localhost:8001')`.

---

## Setup and Launch

### 1. Clone this repository

```bash
git clone https://github.com/neurologic/efish_em_ELL.git
```

### 2. Download and place the data

Download `EM_data_published/` from `[DATA_REPOSITORY_URL]` and place it as a sibling to the cloned `efish_em_ELL/` folder (see [Data Download](#data-download) above).

### 3. Launch Jupyter from the correct directory

**Notebooks must be launched from `efish_em_ELL/Notebooks_Jupyter/`** — this is required for the relative-path logic to work correctly.

```bash
cd efish_em_ELL/Notebooks_Jupyter
jupyter lab
```

The notebooks use `Path.cwd()` (current working directory) to locate both the Python package and the data folder:

- `Path.cwd().parent / 'efish_em'` → resolves to `efish_em_ELL/efish_em/` (the Python package)
- `Path.cwd().parent.parent / 'EM_data_published'` → resolves to the sibling data folder

If you launch Jupyter from any other directory, these paths will not resolve correctly.

---

## Notebook Guide

Each row below gives, for one notebook: **install tier**, **purpose**, **inputs read from `EM_data_published/`**, **outputs written**, and the **paper figure(s)** it feeds. Install tiers are defined above in [Environment Setup](#environment-setup): **tier 1** = base (`pip install -e .`), **tier 2** = `[ecrest]`, **tier 3** = `[cloudvolume]` (macOS / Linux only). Every notebook imports `from efish_em import AnalysisCode as efish`.

| Notebook | Tier | Purpose | Inputs from `EM_data_published/` | Outputs | Paper figure(s) |
|---|---|---|---|---|---|
| `Analyses_published.ipynb` | **1** | Main analysis & figure generation — runs top-to-bottom to reproduce every published connectome panel. Also loads modeling outputs to reproduce modeling panels. | `data_processed_published/{df_type_auto_typed, df_postsyn, df_presyn, df_spine_counts, MG_partial-cat}.csv`, `morphology_cat/*.csv`, `layer-molecular_annotation.json`, `data_VAST/volume_subsample_sg-mg-out_ratio/df_segments_assigned.csv`, `model/*.mat` (data_gc + figure folders) | Figure panels (SVG/PNG) under `Notebooks_Jupyter/figures/` when `save_figures=True` | Figs 1–6; ED Figs 2–8 |
| `CellTyping.ipynb` | **1** | Hierarchical classification of cell types (MG1/MG2, SG1/SG2 and others) from morphology metrics; soma descriptive stats. | `morphology_cat/*.csv`, `MG_partial-cat.csv`, `layer-molecular_annotation.json`, `reconstructions_published/*.json` | `data_processed_published/df_type_auto_typed.csv` | ED Fig 2; cell-subset filter for every downstream notebook |
| `Network-Build.ipynb` | **1** | Extract synapse annotations from eCREST `.json` files and assemble post-/pre-synaptic edge lists. No live Neuroglancer viewer required. | `reconstructions_published/*.json` | `data_processed_published/df_postsyn.csv`, `df_presyn.csv` | Input to `Analyses_published` |
| `neuroglancer-demo-appspot.ipynb` | **1** | Build the three published Neuroglancer state JSONs (shown on the website Gallery) from the classified cell list and synapse edge list. | `reconstructions_published/*.json`, `data_processed_published/df_type_auto_typed.csv`, `df_postsyn.csv`; optional template inspection of `ng_states/em-prrofread-base-agglo.json` | `ng_states/Proofread_MG_Output_MGsyn.json`, `Proofread_Classified_Cells.json`, `Proofread_Unclassified.json` | Website Gallery (not a figure) |
| `eCREST_notebook.ipynb` | **2** | Interactive template for opening/editing/typing a single reconstruction in the live eCREST + Neuroglancer viewer; documents the reconstruction workflow. | `reconstructions_published/*.json`, `Mariela_bigquery_exports_agglo_v230111c_16_crest_proofreading_database.db` | None by default (save is demonstrated but commented out) | Methods |
| `json_to_VASTskel.ipynb` | **2** (Mac/Linux) | Convert eCREST `.json` reconstructions into VAST-compatible skeleton CSVs. Consumes the shipped base-segment → voxel location table (no live BigQuery needed). | `reconstructions_published/*.json`, `base-segs_query_published.parquet`, `data_processed_published/df_type_auto_typed.csv` | Timestamped CSVs under `Notebooks_Jupyter/outputs/vast_skeletons/` (optional `subvolume_apical/` subset) | Input to VAST agglomeration pipeline |
| `morphology_cat_createDF.ipynb` | **3** (Mac/Linux) | Extract per-cell morphology statistics (nodes on axon / basal / apical trees) from precomputed CloudVolume skeletons. | `reconstructions_published/*.json`, `base-segs_query_published.parquet`, `data_processed_published/{df_type_auto_typed, layer-molecular_annotation}`, CloudVolume `gs://efish-public/roi450um_seg32fb16fb_220930/` | `data_processed_published/morphology_cat/*.csv` (df_nodes_ax/bd/ad × type1/type2) | Input to `CellTyping` |
| `Subvolume_dense-set.ipynb` | **3** (Mac/Linux) | Map each segment in the dense-labeled VAST subvolume to a reconstructed-cell ID/type; validate coordinate alignment. | `data_VAST/volume_subsample_sg-mg-out_ratio/actual_coords_isotropic.mat`, `data_VAST/iso_thumbnails_mSEM/16nm_EM_png_stack_5x5/`, `data_processed_published/df_type_auto_typed.csv`, CloudVolume `gs://efish-public/roi450um_seg32fb16fb_220930/` | `data_VAST/volume_subsample_sg-mg-out_ratio/df_segments_assigned.csv` | ED Fig 3 |
| `SpineCounts.ipynb` | **3** (Mac/Linux) | Count spines per depth bin along the apical dendrite, using the shipped precomputed subvolume served by `igneous view` (see Environment Setup). | `reconstructions_published/annotation-spines/*.json`, `data_VAST/volume_subsample_sg-mg-out_ratio/df_segments_assigned.csv`, `df_type_auto_typed.csv`, local `CloudVolume('precomputed://http://localhost:8001')` | `data_processed_published/df_spine_counts.csv` | ED Fig 3 |
| `Blender_make_mesh.ipynb` | **3** (Mac/Linux) | Download and downsample 3D meshes (`.obj`) of reconstructed neurons from the precomputed segmentation for Blender rendering. | `reconstructions_published/*.json`, CloudVolume `gs://efish-public/roi450um_seg32fb16fb_220930/` | `.obj` files under `Notebooks_Jupyter/outputs/blender_obj/` | Fig 1 mesh panels; supplemental videos |

---

## Full Pipeline Workflow

The diagram below traces the processing order from raw EM data to final published figures.
The data processing and analysis can be replicated by utilizing the notebooks in Notebooks_Jupyter/ and these notebooks enable roughly 5 main parallel workflows. Four converge on `Analyses_published.ipynb`; the fifth (`neuroglancer-demo-appspot.ipynb`) publishes the interactive Neuroglancer views shown on the release website [Gallery](https://efish-public.storage.googleapis.com/gallery.html). 
```
Raw mSEM EM volume
  └─▶ gs://efish-public/roi450um_seg32fb16fb_220930/  (Precomputed base segmentation)
        │
        └─▶ eCREST_cli.py  (via eCREST_notebook.ipynb)
              └─▶ reconstructions_published/*.json
                    │
                    ├─── Pipeline 1 ─────────────────────────────────────────
                    │    → Network-Build.ipynb
                    |      inputs: reconstructions_published/*.json
                    │         → df_postsyn.csv, df_presyn.csv  ──▶ Analyses_published
                    │
                    ├─── Pipeline 2 (cell-typing loop) ──────────────────────
                    │    → morphology_cat_createDF.ipynb
                    │      inputs: base-segs_query_published.parquet,
                    │              layer-molecular_annotation.json,
                    │              gs://efish-public/roi450um_seg32fb16fb_220930/,
                    │              df_type_auto_typed.csv  (iterative filter)
                    │         → morphology_cat/*.csv
                    │             → CellTyping.ipynb
                    │               inputs: reconstructions_published/*.json,
                    │                       MG_partial-cat.csv,
                    │                       layer-molecular_annotation.json
                    │                 → df_type_auto_typed.csv
                    │                   ──▶ filter input to many notebooks +
                    │                       Analyses_published
                    │
                    ├─── Pipeline 3 (subvolume → spine counts) ──────────────
                    │    → Subvolume_dense-set.ipynb
                    │      inputs: gs://efish-public/roi450um_seg32fb16fb_220930/, df_type_auto_typed.csv,
                    │              actual_coords_isotropic.mat,
                    │              iso_thumbnails_mSEM/*.png
                    │         → df_segments_assigned.csv
                    |               ─▶ SpineCounts.ipynb
                    │
                    │    precomputed_subvolume-apical-revision/  (SHIPPED)
                    │      └─ served via `igneous view` ─▶ SpineCounts.ipynb
                    |
                    |    → SpineCounts.ipynb
                    │      inputs: annotation-spines/,
                    │              df_segments_assigned.csv,
                    │              df_type_auto_typed.csv
                    │        → df_spine_counts.csv  ──▶ Analyses_published
                    │
                    ├─── Pipeline 4 (3D rendering) ──────────────────────────
                    │    → Blender_make_mesh.ipynb  (uses gs://efish-public/roi450um_seg32fb16fb_220930/ by seg ID)
                    │        → .obj files  ──▶  Blender (external)
                    │                            3D figure panels
                    │
                    └─── Pipeline 5 (Neuroglancer state publishing) ─────────
                         → neuroglancer-demo-appspot.ipynb
                           inputs: reconstructions_published/*.json,
                                   df_type_auto_typed.csv, df_postsyn.csv
                             → ng_states/Proofread_MG_Output_MGsyn.json
                             → ng_states/Proofread_Classified_Cells.json
                             → ng_states/Proofread_Unclassified.json
                                   ──▶ efish EM release website Gallery

Convergence:
  Analyses_published.ipynb
    inputs:
      • df_postsyn.csv, df_presyn.csv              (Pipeline 1)
      • df_type_auto_typed.csv, morphology_cat/    (Pipeline 2)
      • df_segments_assigned.csv, df_spine_counts  (Pipeline 3)
      • reconstructions_published/*.json
      • annotation-spines/
      • layer-molecular_annotation.json
      • MG_partial-cat.csv
      • model/data_gc.mat, model/fig5/*.mat, model/fig6/*.mat,
        model/figS4/*.mat, model/figS7/*.mat, model/figS8/*.mat
                                                   (produced by ELL_net_model_paper/ MATLAB code)
    outputs:
      • Published figure panels (.svg / .png) in Notebooks_Jupyter/figures/
      • Quantitative summary statistics reported in manuscript text
```

### Provenance notes

- **`layer-molecular_annotation.json`** — a Neuroglancer state file containing manually placed layer-boundary annotations made in Neuroglancer's annotation tab. Consumed by `morphology_cat_createDF`, `CellTyping`, and `Analyses_published`.
- **`actual_coords_isotropic.mat`** — generated by the MATLAB helpers `analyze_segs.m` and `segment_center.m` in `data_VAST/matlab-helper-scripts/`. They export segment centers from a segmentation layer built manually over the isotropic segmentation mask.
- **`iso_thumbnails_mSEM/`** — a downsampled/averaged version of the original mSEM volume, used for rapid visual soma detection during subvolume definition.
- **`model/*.mat`** (under `model/data_gc.mat`, `model/fig5/`, `model/fig6/`, `model/figS4/`, `model/figS7/`, `model/figS8/`) — network-modeling outputs produced by the MATLAB code in `ELL_net_model_paper/` (this repository). The `.mat` files are shipped so that `Analyses_published.ipynb` can reproduce modeling panels without re-running the simulations. `model/data_ell_net/` holds the input data consumed by those MATLAB scripts.
- **`ng_states/em-prrofread-base-agglo.json`** — a hand-authored Neuroglancer state used as the base layer reference (inspected by `neuroglancer-demo-appspot.ipynb`). The three output JSONs in `ng_states/` are written by that notebook and power the Gallery links on the release website.
- **`STATIC_published-reconstructions.json`** — a base-segment → reconstructed-cell dictionary used to build the user-friendly static single-segment version of each reconstruction (each cell available as a single agglomerated segment in the public GCS bucket). It is a convenience lookup for archive consumers; no notebook in this pipeline reads it.
- **`df_type_auto_typed.csv`** — written by `CellTyping.ipynb`. Serves as a cell-subset filter consumed by `morphology_cat_createDF`, `Subvolume_dense-set`, `SpineCounts`, `json_to_VASTskel`, and `Analyses_published`. The `morphology_cat_createDF` ↔ `CellTyping` loop is iterative: the first pass uses a preliminary manual typing; later passes consume the automated output.
- **`precomputed_subvolume-apical-revision/`** — ships directly in `EM_data_published/`. It was originally built via a VAST + CloudVolume + Igneous chain, documented below for provenance only. Users do **not** rebuild it.
- **VAST** — see the [VAST / VASTlite](#vast--vastlite) entry in External Tools and Background.

### Provenance of `precomputed_subvolume-apical-revision/` (not required for reproduction)

Shown for transparency — users do **not** run this chain; the final precomputed volume ships in the data archive.

```
df_segments_assigned.csv  (from Subvolume_dense-set.ipynb)
  +
base-segs_query_published.parquet
        │
        └─▶ json_to_VASTskel.ipynb
              └─▶ per-cell VAST skeleton .csv
                    └─▶ VAST (external): segment agglomeration → .raw
                          └─▶ CloudVolume ingestion  (external, no notebook)
                                └─▶ Igneous CLI: mesh + skeletonization
                                      └─▶ precomputed_subvolume-apical-revision/
                                          (ships in EM_data_published)
```

---

## Repository Structure

```
efish_em_ELL/
├── README.md
├── pyproject.toml                 ← install tiers (base, [ecrest], [cloudvolume], [all])
├── static_solve.txt               ← provenance-only pin list of all tiers (not an install target)
├── .gitignore
├── efish_em.mplstyle              ← matplotlib style for publication figures
├── ELL_net_model_paper/           ← MATLAB scripts that produce model/*.mat in EM_data_published
├── Notebooks_Jupyter/             ← launch jupyter lab from here
│   ├── Analyses_published.ipynb
│   ├── CellTyping.ipynb
│   ├── Network-Build.ipynb
│   ├── neuroglancer-demo-appspot.ipynb
│   ├── eCREST_notebook.ipynb
│   ├── json_to_VASTskel.ipynb
│   ├── morphology_cat_createDF.ipynb
│   ├── Subvolume_dense-set.ipynb
│   ├── SpineCounts.ipynb
│   ├── Blender_make_mesh.ipynb
│   └── figures/                   ← output folder written by Analyses_published.ipynb
└── efish_em/                      ← Python package (importable as `from efish_em import AnalysisCode`)
    ├── __init__.py
    ├── AnalysisCode.py
    └── eCREST_cli.py
```

---

## Troubleshooting

**`ModuleNotFoundError: No module named 'efish_em'`**
The `efish_em_ELL` package is not installed in the active environment. From the repo root, run `pip install -e .` (or the tier-2/tier-3 variant — see [Installation](#installation)), then restart the Jupyter kernel.

**`FileNotFoundError` for data files**
Check that `EM_data_published/` is placed as a sibling to `efish_em_ELL/` (not inside it), and that the folder structure matches what is listed under [Expected contents of `EM_data_published/`](#expected-contents-of-em_data_published).

**CloudVolume / Igneous errors on Windows**
`SpineCounts.ipynb` and `Subvolume_dense-set.ipynb` require CloudVolume, which does not support Windows. Run these notebooks on Mac or Linux. The pre-computed output files (`df_spine_counts.csv`, `df_segments_assigned.csv`) are included in `EM_data_published/` so that Windows users can still run `Analyses_published.ipynb`.

**`ImportError` for `neuroglancer`**
The neuroglancer package is only required for `eCREST_notebook.ipynb`. Install it with `pip install neuroglancer` in your conda environment.

**What is the `efish_em_ELL.egg-info/` folder?**
It is auto-generated by `pip install -e .` (or any of the tiered variants). It stores packaging metadata — the rendered `[project]` table from `pyproject.toml`, the flattened dependency list, and the name of the importable package (`efish_em`). Python and pip read it to know that `efish_em_ELL` is installed and where to find it; it is not source code.

Practical implications:

- **You can ignore it.** It is listed in `.gitignore` and is never committed. It lives next to `pyproject.toml` at the repository root.
- **Switching install tiers does not confuse it.** Running `pip install -e ".[ecrest]"` or `pip install -e ".[cloudvolume]"` after an earlier `pip install -e .` in the same environment is safe — pip re-resolves, layers the extras on top, and rewrites the `.egg-info/` metadata to reflect the new state. You do not need to delete it between tier upgrades.
- **Delete it only if metadata looks stale.** If you edit `pyproject.toml` (e.g. change a version pin or add an extra) and `pip show efish_em_ELL` still reports the old values, or if you uninstall the package and want to start clean, run:
  ```bash
  rm -rf efish_em_ELL.egg-info/
  pip install -e .       # or your tier of choice
  ```
  This regenerates the metadata from scratch.
- **Do not move or rename it.** Its location at the repository root (the directory containing `pyproject.toml`) is what lets editable-mode imports resolve back to the source tree.
