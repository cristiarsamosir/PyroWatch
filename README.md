# PyroWatch-ChaosBench

A research project group working on subseasonal wildfire prediction using [ChaosBench](https://github.com/leap-stc/ChaosBench).

## What's in here

```
docs/DATA_SETUP.md                   full guide to the data step
notebooks/01_chaosbench_to_gcs.ipynb  runs the data step
scripts/chaosbench/                   download, upload and verify scripts
```

## Option 1: Try to get the data on your own

Runs on the LEAP-Pangeo JupyterHub. You need write access to
`gs://leap-persistent/<your-user>/`.

1. In a Hub terminal:
   ```bash
   git clone https://github.com/cristiarsamosir/PyroWatch.git
   cd PyroWatch
   ```
2. Open `notebooks/01_chaosbench_to_gcs.ipynb`, set your bucket path in the first cell,
   and run the cells one at a time, top to bottom (not "Run All").
3. When it finishes, run the last cell to verify the upload.

The notebook downloads `climatology`, `lra5`, `oras5` and `era5` from
[Hugging Face](https://huggingface.co/datasets/LEAP/ChaosBench), extracts them, uploads
them to your bucket and deletes the local copies.

Result in bucket:

```
gs://leap-persistent/<your-user>/chaosbench/
  climatology/   era5/   lra5/   oras5/
```

## Option 2: Access directly from GCS without downloading it

This is only applicable for LEAP-Pangeo member. Access it by:
1. In a Hub terminal:
   ```bash
   gcloud storage ls gs://leap-persistent/cristiarsamosir/chaosbench/
   ```
   If it lists `era5/`, `lra5/`, `oras5/`, and `climatology/`, it works.

2. Test reading the data
   ```python
   import xarray as xr
   ds = xr.open_zarr("gs://leap-persistent/cristiarsamosir/chaosbench/era5/era5_full_1.5deg_19791208.zarr")
   ```
### Note on data size

| Dataset | Download (archive) | In the bucket |
|---|---|---|
| `era5` | about 44.7 GB | 16,436 day folders |
| `lra5` | 19.91 GB | 16,436 day folders |
| `oras5` | 34.2 GB| 16,436 day folders |
| `climatology` | 9.21 GB | about 8,077 files |

### Rules to keep 
Once you do your data cleaning or analysis, save your own results under your own folder (for example gs://leap-persistent/<their-user>/pyrowatch/) and the path can be shared to our team.

## References

- [ChaosBench on GitHub](https://github.com/leap-stc/ChaosBench) and
  [Hugging Face](https://huggingface.co/datasets/LEAP/ChaosBench)
- [LEAP data documentation](https://leap-stc.github.io/data/)

