# PyroWatch

Subseasonal wildfire prediction using [ChaosBench](https://github.com/leap-stc/ChaosBench).

## What's in here

```
docs/DATA_SETUP.md                   full guide to the data step
notebooks/01_chaosbench_to_gcs.ipynb  runs the data step
scripts/chaosbench/                   download, upload and verify scripts
```

## Get the data

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

### Note on data size

| Dataset | Download (archive) | In the bucket |
|---|---|---|
| `era5` | about 44.7 GB | 16,436 day folders |
| `lra5` | 19.91 GB | 16,436 day folders |
| `oras5` | 34.2 GB| 16,436 day folders |
| `climatology` | 9.21 GB | about 8,077 files |


## References

- [ChaosBench on GitHub](https://github.com/leap-stc/ChaosBench) and
  [Hugging Face](https://huggingface.co/datasets/LEAP/ChaosBench)
- [LEAP data documentation](https://leap-stc.github.io/data/)

