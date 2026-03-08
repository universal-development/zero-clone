# Data Lake example

Demonstrates syncing multiple sources into a single shared directory using `--dest`.

Layout
- `source-a/dataset1`, `source-b/dataset2`: sample source dirs (simulating different servers)
- `.zero-clone/`: config with rclone.conf, env.sh, and generated list.txt
- `lake/`: shared destination created by `--dest` flag

Run
```
bash examples/data-lake/run.sh
```

After running, all data lands in `lake/`:
```
lake/
  dataset1/users.csv
  dataset2/products.csv
```

In real usage, replace local paths in list.txt with rclone remotes:
```
server-a:data/users     dataset1
server-b:data/products  dataset2
```
