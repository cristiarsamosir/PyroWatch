#!/usr/bin/env bash
# Download one ChaosBench dataset, extract it, upload it to a bucket, clean up.
#
# Usage: bash fetch_dataset.sh <dataset> <bucket_url> [work_dir]
#   e.g. bash fetch_dataset.sh lra5 gs://leap-persistent/<user>/chaosbench ~/chaosbench_work
#
# Disk needed at the peak (during extraction) = archive size + extracted size.
# Set PARTS_ROOT to keep the archive on a different disk than WORK (the extracted data).
# Safe to re-run: finished downloads are skipped, and the upload (rsync) only
# copies what is missing.
set -euo pipefail

# Everything lives in a function and the last line runs it and exits in one go, so
# bash never reads the file again after starting. Rewriting this file while a job
# is running therefore cannot corrupt that job.
main() {
    D="$1"
    BUCKET="${2%/}"
    WORK="${3:-$HOME/chaosbench_work}"
    HERE="$(cd "$(dirname "$0")" && pwd)"
    PARTS="${PARTS_ROOT:-$WORK}/$D/parts"   # archive can live on a different disk than the extracted data
    OUT="$WORK/$D/data"
    UPLOAD="${UPLOAD:-gcloud storage rsync -r}"   # overridden only for local testing

    mkdir -p "$PARTS" "$OUT"

    echo "[1/4] $(date +%T) downloading $D"
    python3 "$HERE/download_parts.py" "$D" "$PARTS"

    echo "[2/4] $(date +%T) extracting $D"
    if [ ! -f "$WORK/$D/.extracted" ]; then
      # --strip-components=1 drops the archive's top folder ("<dataset>_tmp")
      cat "$PARTS"/"${D}"_chunks.tar.gz.* | tar -xzf - --strip-components=1 -C "$OUT"
      touch "$WORK/$D/.extracted"
      rm -rf "$PARTS"          # free the archive as soon as it is extracted
    else
      echo "    already extracted"
    fi

    echo "[3/4] $(date +%T) uploading to $BUCKET/$D"
    $UPLOAD "$OUT" "$BUCKET/$D"

    echo "[4/4] $(date +%T) removing local copy"
    rm -rf "$WORK/$D"

    echo "DONE $D"
}

main "$@"; exit $?
