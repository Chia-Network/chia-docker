#Official Chia Docker Container
Currently latest = head of dev branch, tagged releases to come shortly


## Initialize
```
docker run (optional --expose=58444 to run a testnet node)--name chia (chia-farmer, chia-harvester1 etc.) -d ghcr.io/chia-network/chia:latest (optional -v /path/to/plots:plots)
```

## Config management
```
docker exec -it chia /bin/bash
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

#### remain in the container with a bash shell

Activate venv
```
. ./activate
```

If you have your own keys
```
chia keys add (follow prompt)
```
or
```
echo "keys" | chia keys add -
```

To generate keys
```
chia keys generate
```

If added the optional plots earlier

```
chia plots add -d /plots
```

you can start chia as normal or

```
chia start farmer
optional single purpose node
(chia start farmer-only)
(chia start harvester)
```

verify things are working
```
chia show -s -c
```

drop from shell, leave running Container
```
exit
```

status from outside the container

```
docker exec -it chia venv/bin/chia show -s -c
```

#### or run the same commands externally with venv
```
docker exec -it chia venv/bin/chia keys generate OR docker exec -it chia venv/bin/chia keys add
docker exec -it chia venv/bin/chia plots add -d /plots
docker exec -it chia venv/bin/chia start farmer
```
