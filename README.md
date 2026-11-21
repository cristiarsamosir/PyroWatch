# PyroWatch

Subseasonal wildfire prediction using [ChaosBench](https://github.com/leap-stc/ChaosBench).

> _To fill in: one or two sentences on the research question and approach._

## What's here

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

Result in your bucket:

```
gs://leap-persistent/<your-user>/chaosbench/
  climatology/   era5/   lra5/   oras5/
```

### Note on data size

| Dataset | Download (archive) | After extracting | In the bucket |
|---|---|---|---|
| `era5` | about 44.7 GB | about 48-50 GB | 16,436 day folders |
| `lra5` | 19.91 GB | not measured | 16,436 day folders |
| `oras5` | not measured | not measured | 16,436 day folders |
| `climatology` | 9.21 GB | not measured | about 8,077 files |

- **Disk needed at once:** archive plus extracted data, one dataset at a time. ERA5 is the
  largest: about 45 GB on home storage (the archive) and about 50 GB on `/tmp`
  (the extracted data).
- **Bucket budget:** your LEAP bucket allowance is about 1 TB, shared across everything.
  The four datasets above fit well within it (ERA5 is about 50 GB). Other ChaosBench
  datasets were not measured, and the full Hugging Face repo is about 5.88 TB, so do not
  download everything.
- **Time:** downloads ran at about 120-143 MB/s here (ERA5 download roughly 6-7 minutes).
  Extracting and uploading take longer because the data is millions of small files; no
  total time was measured.
- Sizes come from one run on the LEAP Hub and may differ for you.

## If something goes wrong

- **Server shut down:** re-run the start cell. It resumes where it left off.
- **Out of space:** delete the work folders (`/tmp/chaosbench_work`, `~/chaosbench_parts`)
  and see [`docs/DATA_SETUP.md`](docs/DATA_SETUP.md#troubleshooting).
- **No output for minutes:** commands that list many files are slow. Wait.

## References

- [ChaosBench on GitHub](https://github.com/leap-stc/ChaosBench) and
  [Hugging Face](https://huggingface.co/datasets/LEAP/ChaosBench)
- [LEAP data documentation](https://leap-stc.github.io/data/)

_License and contact: to fill in._
