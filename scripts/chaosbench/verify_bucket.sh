#!/usr/bin/env bash
# Spot-check a ChaosBench copy in a GCS bucket.
#
# Usage: bash verify_bucket.sh gs://leap-persistent/<user>/chaosbench [dataset ...]
#
# For the daily datasets (era5, lra5, oras5) it checks the number of day folders
# and compares the object count of three sample folders (first, middle, last):
# equal counts suggest that no folder was cut off by an interrupted upload.
# For climatology it checks the total number of objects.
# This is a sanity check, not a checksum comparison.
#
# Expected values (override with environment variables if your data differs):
#   EXPECT_DAYS=16436   day folders per daily dataset (1979-2023)
#   EXPECT_CLIM=8077    objects in climatology
set -uo pipefail

BUCKET="${1:?usage: verify_bucket.sh gs://bucket/path [dataset ...]}"
BUCKET="${BUCKET%/}"
shift
DATASETS="${*:-climatology era5 lra5 oras5}"
EXPECT_DAYS="${EXPECT_DAYS:-16436}"
EXPECT_CLIM="${EXPECT_CLIM:-8077}"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
FAIL=0

for d in $DATASETS; do
  echo "== $d"
  if [ "$d" = "climatology" ]; then
    n=$(gcloud storage ls "$BUCKET/$d/**" 2>/dev/null | wc -l)
    if [ "$n" -eq "$EXPECT_CLIM" ]; then echo "   PASS  objects: $n"
    else echo "   CHECK objects: $n (expected $EXPECT_CLIM)"; FAIL=1; fi
    continue
  fi

  gcloud storage ls "$BUCKET/$d/" > "$TMP" 2>/dev/null
  n=$(wc -l < "$TMP")
  if [ "$n" -eq "$EXPECT_DAYS" ]; then echo "   PASS  day folders: $n"
  else echo "   CHECK day folders: $n (expected $EXPECT_DAYS)"; FAIL=1; fi
  [ "$n" -eq 0 ] && continue

  mid=$(( (n + 1) / 2 ))
  counts=""
  for i in 1 "$mid" "$n"; do
    f=$(sed -n "${i}p" "$TMP")
    c=$(gcloud storage ls -r "$f" 2>/dev/null | wc -l)
    echo "   sample $i: $c lines  ($(basename "$f"))"
    counts="$counts $c"
  done
  uniq_counts=$(echo $counts | tr ' ' '\n' | sort -u | wc -l)
  if [ "$uniq_counts" -eq 1 ]; then echo "   PASS  sample folders have equal counts"
  else echo "   CHECK sample folders differ:$counts"; FAIL=1; fi
done

echo
if [ "$FAIL" -eq 0 ]; then echo "All checks passed."; else echo "Some checks need a look (see CHECK above)."; fi
exit "$FAIL"
