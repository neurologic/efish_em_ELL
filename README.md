# efish_em

Code repository accompanying:

**Perks, Petkova, Muller et al. (2025). "Connectome analysis of a recurrent multi-layer network for continual learning in electric fish."**

This repository contains Jupyter notebooks and Python utilities for processing and analyzing data from the electrosensory lobe (ELL) connectome of *Gnathonemus petersii* (weakly electric fish).

---

## Data Download

The analysis data (`EM_data_published/`) is hosted separately from this repository due to file size constraints.

**Download from:** `[DATA_REPOSITORY_URL]`  *(placeholder — DOI/URL will be added upon publication)*

After downloading and extracting, place the `EM_data_published/` folder **as a sibling** to this cloned repository, so your directory structure looks like:

```
your_directory/
├── EM_data_published/      ← downloaded data archive
└── efish_em/               ← this GitHub repository
```

### Expected contents of `EM_data_published/`

```
EM_data_published/
├── reconstructions_published/      ← eCREST .json cell graph files
│   └── annotation-spines/
├── data_processed_published/       ← processed CSVs created and then used by data processing and analysis notebooks
│   ├── df_type_auto_typed.csv
│   ├── df_postsyn.csv
│   ├── df_presyn.csv
│   ├── df_spine_counts.csv
│   ├── MG_partial-cat.csv
│   ├── layer-molecular_annotation.json
│   └── morphology_cat/
├── data_VAST/
│   └── volume_subsample_sg-mg-out_ratio/
├── data_gc.mat
├── fig6/
├── fig7/
├── figS3/
├── figS6/
└── figS7/
```

> **Note:** If your downloaded archive contains a folder named `figS4/`, rename it to `figS3/` before running notebooks:
> ```bash
> mv EM_data_published/figS4 EM_data_published/figS3
> ```

---

## External Tools and Background

Several external tools were used in the data collection and processing pipeline. Brief descriptions and links are provided below for context.

### eCREST (Connectome Reconstruction and Exploration Simple Tool)

eCREST is a CLI-based Python interface built on top of [CREST](https://github.com/ashapsoncoe/CREST) (by Alex Shapson-Coe). It enables users to (1) proofread biological objects and (2) identify individual network pathways, connections, and cell types in the [Neuroglancer](https://github.com/google/neuroglancer) interface.

In this project, eCREST was used throughout the reconstruction phase to annotate synapses and cell types for all reconstructed neurons. The `eCREST_cli.py` module in this repository contains the `ecrest` class used during that process. The `eCREST_notebook.ipynb` documents the reconstruction workflow.

### VAST / VASTlite

[VASTlite](https://lichtman.rc.fas.harvard.edu/vast/) (Volume Annotation and Segmentation Tool, Harvard Lichtman Lab) is a tool for annotating and editing segments in large EM volumes.

In this project, VAST was used to combine and manually correct automated segment boundaries from the original EM database. `json_to_VASTskel.ipynb` converts eCREST `.json` reconstruction files into VAST-compatible skeleton format, which enabled: (1) segment editing and quality control, (2) generation of vectorized skeletons for morphological analysis (input to `Igneous_pipeline.ipynb`), and (3) generation of Blender-compatible `.obj` mesh files for 3D figure panels.

### CloudVolume

[cloud-volume](https://github.com/seung-lab/cloud-volume) (Seung Lab) is a Python library for reading and writing volumetric datasets stored in [Neuroglancer Precomputed](https://github.com/google/neuroglancer/blob/master/src/datasource/precomputed/README.md) format.

In this project, CloudVolume was used in `SpineCounts.ipynb` to access the segmented EM subvolume and identify which cells occupy a defined bounding box for apical dendrite length measurements.

> **Important:** CloudVolume does not support Windows. It must be run on Mac or Linux.

### Igneous

[Igneous](https://github.com/seung-lab/igneous) (Seung Lab) is a Python-based pipeline for processing large volumetric segmentations, including meshing, skeletonization, and downsampling.

In this project, Igneous was used in `Igneous_pipeline.ipynb` to mesh and skeletonize select segments (with preprocessing in json_to_VASTskel) from the EM subvolume and serve them locally (via `igneous view`) so that CloudVolume could query it. Used for apical dendrite length analysis (Figure 2A).

### Blender

[Blender](https://www.blender.org/) is open-source 3D creation software. `Blender_make_mesh.ipynb` uses the Blender Python API (`bpy`) to generate 3D mesh renderings of reconstructed neurons for figure panels (Figure 1D–H).

> **Note:** `Blender_make_mesh.ipynb` must be run from within Blender's built-in Python scripting environment, not from the standard `efish_em` conda environment.

---

## Environment Setup

### Create and activate the conda environment

```bash
conda create --name efish_em python=3.8
conda activate efish_em
conda install -c conda-forge scipy matplotlib seaborn pandas tqdm
pip install networkx scikit-learn h5py
```

### Optional packages

Install these only if you need to run specific notebooks:

```bash
# For SpineCounts.ipynb and Igneous_pipeline.ipynb
# (Mac/Linux only — CloudVolume does not support Windows)
pip install cloud-volume igneous

# For eCREST_notebook.ipynb (live Neuroglancer viewer and reconstruction workflow)
pip install neuroglancer igraph 
```

---

## Setup and Launch

### 1. Clone this repository

```bash
git clone https://github.com/neurologic/efish_em.git
```

### 2. Download and place the data

Download `EM_data_published/` from `[DATA_REPOSITORY_URL]` and place it as a sibling to the cloned `efish_em/` folder (see [Data Download](#data-download) above).

### 3. Launch Jupyter from the correct directory

**Notebooks must be launched from `efish_em/Notebooks_Jupyter/`** — this is required for the relative path logic to work correctly.

```bash
cd efish_em/Notebooks_Jupyter
jupyter lab
```

The notebooks use `Path.cwd()` (current working directory) to locate both the Python package and the data folder:

- `Path.cwd().parent / 'efish_em'` → resolves to `efish_em/efish_em/` (the Python package)
- `Path.cwd().parent.parent / 'EM_data_published'` → resolves to the sibling data folder

If you launch Jupyter from any other directory, these paths will not resolve correctly.

---

## Notebook Guide

The table below maps each notebook to its purpose, the files it produces, and the corresponding paper figures.

| Notebook | Purpose | Output | Paper Figure(s) |
|---|---|---|---|
| `Analyses_published.ipynb` | Main analysis and figure generation — runs top-to-bottom to reproduce all published connectome results/figures and modelling figures (refer to modeling code for reproducing modeling results) | Figures | Figs 2C/D, 3, 4, 5, 6, 7; Extended Data S3–S7 |
| `SpineCounts.ipynb` | Spine count and apical dendrite length from EM subvolume *(requires CloudVolume/Igneous; Mac/Linux only)* | `data_processed_published/df_spine_counts.csv` | Fig 2A, 2B |
| `Network-Build.ipynb` | Build synapse edge lists from eCREST reconstruction files | `data_processed_published/df_postsyn.csv`, `df_presyn.csv` | Input to `Analyses_published` |
| `CellTyping.ipynb` | Morphological classification of cell types (MG1/MG2, SG1/SG2); soma location analysis | `data_processed_published/df_type_auto_typed.csv` | Input to `Analyses_published` |
| `morphology_cat_createDF.ipynb` | Extract morphological node statistics from eCREST files | `data_processed_published/morphology_cat/*.csv` | Input to `CellTyping` |
| `Igneous_pipeline.ipynb` | Process EM subvolume segments to assign cell type labels; requires running local Igneous server *(Mac/Linux only)* | `data_VAST/volume_subsample_sg-mg-out_ratio/df_segments_assigned.csv` | Fig 2A |
| `json_to_VASTskel.ipynb` | Convert eCREST `.json` files to VAST skeleton format; also produces Blender `.obj` files | VAST skeleton files; Blender `.obj` files | Fig 1D–H; input to `Igneous_pipeline` |
| `Blender_make_mesh.ipynb` | Generate 3D mesh renderings of reconstructed neurons *(must be run inside Blender's Python environment)* | Rendered 3D figure panels | Fig 1D–H |
| `VAST_image_manip.ipynb` | Process and annotate EM image exports from VAST | Processed image files | Fig 1D; Extended Data S2 |
| `eCREST_notebook.ipynb` | Documents the eCREST reconstruction and annotation workflow used to collect the data | — | Methods |

---

## Full Pipeline Workflow

The notebooks form a pipeline. The diagram below shows the processing order from raw EM data to final published figures:

```
eCREST reconstruction (ecrest class in eCREST_cli.py)
        │
        ├─→ reconstructions_published/*.json
        │
        ├─→ json_to_VASTskel.ipynb ──→ VAST skeleton files
        │         │                          │
        │         │                    Igneous_pipeline.ipynb
        │         │                          │
        │         │                    df_segments_assigned.csv
        │         │                          │
        │         └──→ Blender .obj files    └──→ SpineCounts.ipynb
        │                    │                          │
        │             Blender_make_mesh.ipynb    df_spine_counts.csv
        │                    │                          │
        │             3D figure panels                  │
        │                                               │
        ├─→ morphology_cat_createDF.ipynb               │
        │         │                                     │
        │   morphology_cat/*.csv                        │
        │         │                                     │
        ├─→ CellTyping.ipynb                            │
        │         │                                     │
        │   df_type_auto_typed.csv                      │
        │         │                                     │
        └─→ Network-Build.ipynb                         │
                  │                                     │
            df_postsyn.csv                              │
            df_presyn.csv                               │
                  │                                     │
                  └──────────────────────┬──────────────┘
                                         │
                               Analyses_published.ipynb
                                         │
                                   Published figures
```

---

## Repository Structure

```
efish_em/
├── README.md
├── .gitignore
├── efish_em.mplstyle          ← matplotlib style for publication figures
├── matplotlib_default.mplstyle
├── settings_dict.json         ← used only by eCREST_notebook.ipynb (not needed for analysis)
├── Notebooks_Jupyter/         ← launch jupyter lab from here
│   ├── Analyses_published.ipynb
│   ├── SpineCounts.ipynb
│   ├── Network-Build.ipynb
│   ├── CellTyping.ipynb
│   ├── morphology_cat_createDF.ipynb
│   ├── Igneous_pipeline.ipynb
│   ├── json_to_VASTskel.ipynb
│   ├── Blender_make_mesh.ipynb
│   ├── VAST_image_manip.ipynb
│   └── eCREST_notebook.ipynb
└── efish_em/                  ← Python package (imported as `efish` in notebooks)
    ├── __init__.py
    ├── AnalysisCode.py
    └── eCREST_cli.py
```

---

## Troubleshooting

**`ModuleNotFoundError: No module named 'AnalysisCode'`**  
You launched Jupyter from the wrong directory. Make sure to `cd efish_em/Notebooks_Jupyter` before running `jupyter lab`.

**`FileNotFoundError` for data files**  
Check that `EM_data_published/` is placed as a sibling to `efish_em/` (not inside it), and that the folder structure matches what is listed under [Expected contents of `EM_data_published/`](#expected-contents-of-em_data_published).

**CloudVolume / Igneous errors on Windows**  
`SpineCounts.ipynb` and `Igneous_pipeline.ipynb` require CloudVolume, which does not support Windows. Run these notebooks on Mac or Linux. The pre-computed output files (`df_spine_counts.csv`, `df_segments_assigned.csv`) are included in `EM_data_published/` so that Windows users can still run `Analyses_published.ipynb`.

**`ImportError` for `neuroglancer`**  
The neuroglancer package is only required for `eCREST_notebook.ipynb`. Install it with `pip install neuroglancer` in your conda environment.
