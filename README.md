


# Build

```bash
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 --output=type=local,dest=dist .
mv dist/linux_amd64/cage dist/cage-amd64
mv dist/linux_arm64/cage dist/cage-arm64
mv dist/linux_arm_v7/cage dist/cage-armhf
```

# Test patches
To easily test existing patches and develop new ones, run :

```bash
export REF="v0.2.0"
if test -d cage; then
  cd cage
  git fetch origin "$REF"
  git checkout "$REF"
else
  git clone --filter=blob:none --branch "$REF" https://github.com/cage-kiosk/cage.git
cd cage
fi
git am ../patches/*.patch
```

# Patch development
To develop a new patch, start from a fresh clone with all patches applied (see above)

```bash
# edit files in cage/
git add cage/
git commit -m "Brief: describe the change"
```

```bash
# from repo root, outputs patches numbered in the patches/ folder
rm -rf patches/*
(cd cage && git format-patch --output-directory ../patches $REF..HEAD --start-number 001)
```


# Maintenance & troubleshooting
- If a `git am` fails, inspect the failing patch with:

```bash
git am --show-current-patch=diff
```

Or to get more interactive context, try to apply the patch using `git apply --index "../patches/[...]"` and inspect the resulting index and working tree to understand the failure.


- If whitespace or trivial hunks cause failures, try `git am --3way --whitespace=nowarn` to allow three-way merges and ignore whitespace-only differences.


