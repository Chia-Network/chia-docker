#Official Chia Docker Container
Currently latest = head of dev branch, tagged releases to come shortly


## Initialize
```
Docker exec -it chia:latest /bin/bash (optional -v /path/to/plots:plots)

. ./activate

chia init
```

## Config management
```
vim (or nano if you prefer) ~/.chia/testnet/config/config.yaml
```

modify the line
```
self_hostname: &self_hostname "localhost"
```
to match
```
self_hostname: &self_hostname "127.0.0.1"
```

#### optional: remote harvester

```
 harvester:
  # The harvester server (if run) will run on this port
  port: 8448
  farmer_peer:
    host: *self_hostname
    port: 8447
```
include the proper host and port for your remote farmer node or container.

## Starting Chia Blockchain

If you have your own keys
```
chia keys add
```

To generate keys
```
chia keys generate
```

If added the options plots earlier

```
chia plots add -d /plots
```

you can start chia as normal

```
chia start farmer
```
