# ChaosBench data setup on LEAP-Pangeo

This guide gets the ChaosBench inputs from Hugging Face into your own Google Cloud
bucket on the LEAP-Pangeo JupyterHub, without running out of home-directory space.
It is the data step of PyroWatch (subseasonal wildfire prediction using ChaosBench).

Datasets covered: `climatology`, `lra5`, `oras5`, `era5`. Any other ChaosBench
dataset can be added with one line (see [Other datasets](#other-datasets)).

Sources:
[ChaosBench on GitHub](https://github.com/leap-stc/ChaosBench) ·
[ChaosBench on Hugging Face](https://huggingface.co/datasets/LEAP/ChaosBench) ·
[LEAP data documentation](https://leap-stc.github.io/data/)

## Why this is not just `process.sh`

On Hugging Face each dataset is a split `.tar.gz` (for example ERA5 is
`era5_chunks.tar.gz.aa` of 42.95 GB plus a second part). The official
`process.sh` joins the parts and then extracts, which needs 2-3x the dataset size
on disk, and a 50 GB Hub home cannot hold that. Copying the extracted folder to GCS
through the JupyterLab file browser was also slow and unreliable.

The pipeline here does this for each dataset instead:

1. **Download** the archive parts to disk (resumable, retries dropped connections).
2. **Extract** them (the archive is deleted right after a successful extract).
3. **Upload** with `gcloud storage rsync` (parallel; skips files already in the bucket).
4. **Delete** the local copy.

## Requirements

- A LEAP-Pangeo Hub account with write access to `gs://leap-persistent/<your-user>/`
  (use `leap-persistent`, not `leap-scratch`, which deletes after 7 days; write only
  inside your own username folder).
- `gcloud` (already in the Hub image) and Python 3 (standard library only).
- Local disk, because the peak is archive size + extracted size:

| Dataset | Archive | Extracted | Notes |
|---|---|---|---|
| climatology | 9.21 GB | about 8,077 files | observed |
| lra5 | 19.91 GB (one part) | not measured | observed archive size |
| oras5 | not measured | not measured | |
| era5 | about 44.7 GB (two parts) | about 48-50 GB | observed |

ERA5 needs about 95 GB in total at the peak, which is more than `/tmp` (about 79 GB
free on the Hub used here). The notebook therefore puts the **archive on home storage**
(`PARTS_ROOT`) and only the **extracted data on `/tmp`** (`WORK`). That needs about
45 GB of free home quota. If your home limit is lower, see [Troubleshooting](#troubleshooting).

## Quick start

On the Hub, in a terminal:

```bash
cd ~
git clone https://github.com/cristiarsamosir/PyroWatch.git
cd PyroWatch
```

Open `notebooks/01_chaosbench_to_gcs.ipynb` in JupyterLab and run the cells **one at a
time, top to bottom** (do not use "Run All" while a transfer is running).

1. Edit the bucket line in the config cell (or set `CHAOSBENCH_BUCKET` before starting
   JupyterLab) so it points at your own folder.
2. Run the checks cell, then the start cell. The transfer runs in the background and
   writes `transfer.log` next to the notebook.
3. Re-run the watch cell now and then. Each dataset ends with `DONE <dataset>`.
4. Run the verify cell at the end.

Without the notebook, from a terminal:

```bash
export BUCKET=gs://leap-persistent/<your-user>/chaosbench
export WORK=/tmp/chaosbench_work
export PARTS_ROOT=$HOME/chaosbench_parts
for d in climatology lra5 oras5 era5; do
  bash scripts/chaosbench/fetch_dataset.sh $d "$BUCKET" "$WORK" || break
done
bash scripts/chaosbench/verify_bucket.sh "$BUCKET"
```

## What ends up in the bucket

```
gs://leap-persistent/<your-user>/chaosbench/
  climatology/   about 8,077 files
  era5/          16,436 day folders  era5_full_1.5deg_YYYYMMDD.zarr   (1979-2023)
  lra5/          16,436 day folders  lra5_full_1.5deg_YYYYMMDD.zarr
  oras5/         16,436 day folders
```

`scripts/chaosbench/verify_bucket.sh` checks the folder counts and compares the object
count of three sample folders per dataset (all equal means no folder was cut off by an
interrupted upload). For `lra5` a day folder listed 234 lines in the run this guide was
written from. It is a sanity check, not a checksum comparison.

## Reading the data

Each day folder is a zarr store. This is untested against the real data, but with
`xarray`, `zarr` and `gcsfs` installed it should look like:

```python
import xarray as xr
ds = xr.open_zarr("gs://leap-persistent/<your-user>/chaosbench/era5/era5_full_1.5deg_19791208.zarr")
```

## Other datasets

The README of ChaosBench lists control forecasts (`ukmo`, `ncep`, `cma`, `ecmwf`),
ensembles (`ukmo_ensemble`, `ncep_ensemble`, `cma_ensemble`, `ecmwf_ensemble`) and
model outputs (`panguweather`, `fourcastnetv2`, `graphcast`). Add the name to the
dataset list in the notebook's config cell. Their archive layout and sizes were **not
checked** for this guide; the whole Hugging Face repo is about 5.88 TB, so add them one at a
time and watch your bucket budget (about 1 TB shared across everything). If a dataset
fails with `no parts found`, its files are named differently; look at
`datasets/LEAP/ChaosBench/tree/main/<dataset>` on Hugging Face.

## Reproducibility notes

- `download_parts.py` reads from the `main` branch of the Hugging Face dataset. To pin
  an exact version, set `CHAOSBENCH_REVISION=<commit hash>` before running.
- The scripts use only the Python standard library and `gcloud`; nothing else to install.
- Everything is idempotent: re-running a dataset keeps finished downloads and the upload
  only copies what is missing.

