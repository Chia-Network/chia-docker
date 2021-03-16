#Official Chia Docker Container
Currently latest = head of dev branch, tagged releases to come shortly


## Initialize
```
Docker run -d chia:latest /bin/bash --name chia (optional -v /path/to/plots:plots)
```

## Config management
```
docker exec --entrypoint /bin/bash -it chia
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
remain in the container with a bash shell, alternatively you can run docker exec commands with chiarun

If you have your own keys
```
chia keys add
docker exec -it chia echo "keys" | chiarun keys add
```

To generate keys
```
chia keys generate
docker exec -it chia chiarun keys generate
```

If added the options plots earlier

```
chia plots add -d /plots
docker exec -it chia chiarun plots add -d /plots
```

you can start chia as normal

```
chia start farmer
docker exec -it chia chiarun start farmer
```
