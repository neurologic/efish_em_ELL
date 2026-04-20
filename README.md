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
│   └── volume_subsample_sg-mg-out_ratio/  ← subvolume CSVs + precomputed segmentation
├── data_gc.mat
├── base-segs_query_published.csv          ← base-segment → voxel-location table (BigQuery export)
├── base-segs_query_published.parquet      ← same table in Parquet format
├── published_reconstructions.json         ← reconstruction → meshed-segment lookup for public GS bucket
├── Mariela_bigquery_exports_agglo_v230111c_16_crest_proofreading_database.db
├── fig5/
├── fig6/
├── figS4/
├── figS7/
└── figS8/
```

**Modeling Data and Scripts**
Modeling data were obtained via separately-hosted custom scripts written in Matlab (Muller: [DOI]). The processed data from the modeling simulations are included in EM_data_published for Figure reproduction purposes. The containing folder name matches the figure number in the final manuscript (`fig5/`, `fig6/`, `figS4/`, `figS7/`, `figS8/`). The `.mat` files within these folders carry the filenames used at the time of manuscript submission.

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
5. **Igneous command-line pipeline** — `igneous mesh forge`, `igneous mesh merge`, and `igneous skeleton` steps to produce meshes and skeletons served from the precomputed directory.

To use the shipped precomputed volume, serve it locally with Igneous:

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

> **About `requirements.txt`:** this file is a provenance record of the exact conda environment used on the author's Mac to produce the published figures. It is **not** an installation target (many pins are osx-64 specific). Use the `pip install` commands below instead.

### Install tier 1 — base (Windows / macOS / Linux)

Runs the main analysis notebooks (`Analyses_published.ipynb`, `CellTyping.ipynb`) — sufficient to reproduce every published quantitative data panel (does not include mesh creation for Blender renderings).

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

> **Important:** `cloud-volume` pins specific versions of `numpy`, `protobuf`, and a few other deps. Installing it **after** the base package can force a silent numpy downgrade that breaks the already-installed scientific stack. For clean results, install `cloud-volume` **first** so its pins win, then layer the rest on top:

```bash
# macOS / Linux only
pip install cloud-volume                          # 1) install cloud-volume first
pip install -e ".[cloudvolume,ecrest]"            # 2) then add the extras (includes trimesh, neuprint, igneous, neuroglancer, python-igraph)
pip install -e .                                  # 3) finally install the base package (accepts cloud-volume's numpy pin)
```

If `pip install -e ".[cloudvolume]"` succeeds without complaint, steps (2) and (3) can be collapsed into `pip install -e ".[all]"`.

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

The table below maps each notebook to its purpose, the install tier it requires, the files it produces, and the corresponding paper figures. Install tiers are defined above in [Environment Setup](#environment-setup): **tier 1** = base (`pip install -e .`), **tier 2** = `[ecrest]`, **tier 3** = `[cloudvolume]` (macOS / Linux only).

| Notebook | Install tier | Purpose | Output | Paper Figure(s) |
|---|---|---|---|---|
| `Analyses_published.ipynb` | **tier 1** | Main analysis and figure generation — runs top-to-bottom to reproduce published connectome results/figures (refer to modeling code for reproducing modeling results) | Figures | Figs 1–6; Extended Data Figs 2-8 |
| `CellTyping.ipynb` | **tier 1** | Morphological classification of cell types (MG1/MG2, SG1/SG2); soma location analysis | `data_processed_published/df_type_auto_typed.csv` | Extended Data Fig. 2; input to `Analyses_published` |
| `Network-Build.ipynb` | **tier 1** | Build synapse edge lists from eCREST reconstruction files (uses `AnalysisCode.load_ecrest_celldata`; no live eCREST viewer) | `data_processed_published/df_postsyn.csv`, `df_presyn.csv` | Input to `Analyses_published` |
| `eCREST_notebook.ipynb` | **tier 2** | Documents the eCREST reconstruction and annotation workflow (live Neuroglancer viewer) | — | Methods |
| `morphology_cat_createDF.ipynb` | **tier 3** (Mac/Linux) | Extract morphological node statistics from eCREST files via CloudVolume skeletons | `data_processed_published/morphology_cat/*.csv` | Input to `CellTyping` |
| `json_to_VASTskel.ipynb` | **tier 3** (Mac/Linux) | Convert eCREST `.json` files to VAST-compatible skeleton format | VAST skeleton CSV files (under `Notebooks_Jupyter/outputs/vast_skeletons/`) | Input to VAST agglomeration pipeline |
| `Subvolume_dense-set.ipynb` | **tier 3** (Mac/Linux) | Assign cell-type labels to segments in the precomputed EM subvolume | `data_VAST/volume_subsample_sg-mg-out_ratio/df_segments_assigned.csv` | Extended Data Fig. 4 |
| `SpineCounts.ipynb` | **tier 3** (Mac/Linux) | Spine count and apical dendrite length from EM subvolume (needs a local `igneous view` server; see Environment Setup) | `data_processed_published/df_spine_counts.csv` | Extended Data Fig. 4 |
| `Blender_make_mesh.ipynb` | **tiers 2 + 3** (Mac/Linux) | Generate 3D mesh renderings (.obj) of reconstructed neurons | `.obj` files (under `Notebooks_Jupyter/outputs/blender_obj/`) | Fig 1 panels |

---

## Full Pipeline Workflow

The notebooks form a pipeline. The diagram below shows the processing order from raw EM data to final published figures:

```
eCREST_cli.py  (ecrest class, used interactively via eCREST_notebook.ipynb)
        │
        └─→ reconstructions_published/*.json   (+ annotation-spines/ sub-annotations)
                 │
                 ├─→ morphology_cat_createDF.ipynb
                 │        (+ base-segs_query_published.parquet,
                 │           layer-molecular_annotation.json,
                 │           df_type_auto_typed.csv  [iterative — filters cells to (re)skeletonize],
                 │           CloudVolume gs://fish-ell/…)
                 │        ↓
                 │    data_processed_published/morphology_cat/*.csv
                 │        │
                 │        ↓
                 │    CellTyping.ipynb
                 │        (+ reconstructions_published/*.json,
                 │           MG_partial-cat.csv,
                 │           layer-molecular_annotation.json)
                 │        ↓
                 │    df_type_auto_typed.csv  ──────────────────┐
                 │                                               │  consumed downstream by:
                 │                                               │    json_to_VASTskel,
                 │                                               │    morphology_cat_createDF (iterative),
                 │                                               │    Subvolume_dense-set,
                 │                                               │    SpineCounts,
                 │                                               │    Analyses_published
                 │                                               │
                 ├─→ Network-Build.ipynb  (reads annotation-spines/; CloudVolume)
                 │        ↓
                 │    df_postsyn.csv, df_presyn.csv  ────────────┤
                 │                                               │
                 ├─→ json_to_VASTskel.ipynb
                 │        (+ base-segs_query_published.parquet,
                 │           df_type_auto_typed.csv)
                 │        ↓
                 │    per-cell VAST skeleton .csv
                 │        │
                 │        ↓
                 │    VAST segment agglomeration → .raw export
                 │        ↓
                 │    Igneous CLI pipeline  (see External Tools section)
                 │        ↓
                 │    precomputed_subvolume-apical-revision/
                 │        ↓  (served locally via `igneous view`)
                 │    SpineCounts.ipynb
                 │        (+ df_type_auto_typed.csv,
                 │           df_segments_assigned.csv)
                 │        ↓
                 │    df_spine_counts.csv  ──────────────────────┤
                 │                                               │
                 └─→ Subvolume_dense-set.ipynb
                          (CloudVolume gs://fish-ell/…;
                           + df_type_auto_typed.csv,
                             actual_coords_isotropic.mat,
                             iso_thumbnails_mSEM/*.png)
                          ↓
                      df_segments_assigned.csv  ─────────────────┤
                                                                 │
                                                                 │
  Blender_make_mesh.ipynb   (CloudVolume gs:// by seg ID; no     │
           ↓                 eCREST json or CSV input)           │
       .obj files → 3D figure panels                             │
                                                                 │
  fig5/*.mat, fig6/*.mat  (modeling data) ───────────────────────┤
                                                                 │
                                                                 ↓
                                                  Analyses_published.ipynb
                                                     (+ reconstructions_published/*.json
                                                        + annotation-spines/,
                                                        layer-molecular_annotation.json)
                                                                 │
                                                                 ↓
                                                      Published figures;
                                                      published_reconstructions.json
```

**Note.** `morphology_cat_createDF.ipynb` reads `df_type_auto_typed.csv` for filtering which cells to (re)skeletonize, and `CellTyping.ipynb` writes that file — so the `morphology_cat` ↔ `CellTyping` edge is iterative. First-pass runs use a preliminary manual type assignment; subsequent passes consume the automated output. This is a development-time loop, not a per-publication dependency.

---

## Repository Structure

```
efish_em_ELL/
├── README.md
├── LICENSE
├── .gitignore
├── requirements.txt
├── efish_em.mplstyle              ← matplotlib style for publication figures
├── Notebooks_Jupyter/             ← launch jupyter lab from here
│   ├── Analyses_published.ipynb
│   ├── SpineCounts.ipynb
│   ├── Subvolume_dense-set.ipynb
│   ├── Network-Build.ipynb
│   ├── CellTyping.ipynb
│   ├── morphology_cat_createDF.ipynb
│   ├── json_to_VASTskel.ipynb
│   ├── Blender_make_mesh.ipynb
│   └── eCREST_notebook.ipynb
└── efish_em/                      ← Python package (importable as `AnalysisCode as efish`)
    ├── __init__.py
    ├── AnalysisCode.py
    └── eCREST_cli.py
```

---

## Troubleshooting

**`ModuleNotFoundError: No module named 'AnalysisCode'`**
You launched Jupyter from the wrong directory. Make sure to `cd efish_em_ELL/Notebooks_Jupyter` before running `jupyter lab`.

**`FileNotFoundError` for data files**
Check that `EM_data_published/` is placed as a sibling to `efish_em_ELL/` (not inside it), and that the folder structure matches what is listed under [Expected contents of `EM_data_published/`](#expected-contents-of-em_data_published).

**CloudVolume / Igneous errors on Windows**
`SpineCounts.ipynb` and `Subvolume_dense-set.ipynb` require CloudVolume, which does not support Windows. Run these notebooks on Mac or Linux. The pre-computed output files (`df_spine_counts.csv`, `df_segments_assigned.csv`) are included in `EM_data_published/` so that Windows users can still run `Analyses_published.ipynb`.

**`ImportError` for `neuroglancer`**
The neuroglancer package is only required for `eCREST_notebook.ipynb`. Install it with `pip install neuroglancer` in your conda environment.
