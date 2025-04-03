# Official Chia Docker Container

## Quick Start

These examples shows valid setups using Chia for both docker run and docker-compose. Note that you should read some documentation at some point, but this is a good place to start.

### Docker run
Simple example:
```bash
docker run --name chia --expose=8444 -v /path/to/plots:/plots -d ghcr.io/chia-network/chia:latest
```
Syntax
```bash
docker run [--name <container-name>] [--expose=<port>] [-v </path/to/plots:/plots>] -d ghcr.io/chia-network/chia:latest
```
Optional Docker parameters:
- Give the container a name: `--name=chia`
- Accept incoming connections: `--expose=8444`
- Volume mount plots: `-v /path/to/plots:/plots`


### Docker compose

```yaml
version: "3.6"
services:
  chia:
    container_name: chia
    restart: unless-stopped
    image: ghcr.io/chia-network/chia:latest
    ports:
      - 8444:8444
    volumes:
      - /path/to/plots:/plots
```

## Configuration

You can modify the behavior of your Chia container by setting specific environment variables.

### Timezone

Set the timezone for the container (optional, defaults to UTC).
Timezones can be configured using the `TZ` env variable. A list of supported time zones can be found [here](http://manpages.ubuntu.com/manpages/focal/man3/DateTime::TimeZone::Catalog.3pm.html)
```bash
-e TZ="America/Chicago"
```

### Add your custom keys

To use your own keys pass a file with your mnemonic as arguments on startup
```bash
-v /path/to/key/file:/path/in/container -e keys="/path/in/container"
```
or pass keys into the running container with your mnemonic
```bash
docker exec -it <container-name> venv/bin/chia keys add
```
alternatively you can pass in your local keychain, if you have previously deployed chia with these keys on the host machine
```bash
-v ~/.local/share/python_keyring/:/root/.local/share/python_keyring/
```
or if you would like to persist the entire mainnet subdirectory and not touch the key directories at all
```bash
-v ~/.chia/mainnet:/root/.chia/mainnet -e keys="persistent"
```


### Persist configuration, db, and keyring

You can persist whole db and configuration, simply mount it to Host.
```bash
-v ~/.chia:/root/.chia \
-v ~/.chia_keys:/root/.chia_keys
```

### Farmer only

To start a farmer only node pass
```bash
-e service="farmer-only"
```

### Harvester only

To start a harvester only node pass
```bash
-e service="harvester" -e farmer_address="addres.of.farmer" -e farmer_port="portnumber" -v /path/to/ssl/ca:/path/in/container -e ca="/path/in/container" -e keys="none"
```

### Configure full_node peer

To set the full_node peer's hostname and port, set the "full_node_peer" environment variable with the format `hostname:port`
```bash
-e full_node_peer="node:8444"
```
This will configure the full_node peer hostname and port for the wallet, farmer, and timelord sections of the config.yaml file.

### Configure trusted full_nodes peers for wallets

You can specify a list of trusted full_node peers for your wallet by setting the `trusted_peers` environment variable with a comma-separated list of address:port pairs.

NOTE: You should only configure trusted full_nodes that you manage.

```bash
-e trusted_peers=="1.2.3.4:8444,4.3.2.1:8444"
```

At this time, only IP addresses are supported. Domains will not be added to your config as a trusted peer.

See the [trusted peer documentation](https://docs.chia.net/faq/?_highlight=trusted#what-are-trusted-peers-and-how-do-i-add-them) to understand what trusted nodes are.

### Plots

The `plots_dir` environment variable can be used to specify the directory containing the plots, it supports PATH-style colon-separated directories.

Or, you can simply mount `/plots` path to your host machine.

Set the environment variable `recursive_plot_scan` to `true` to enable the recursive plot scan configuration option.

### Adding mounts while running

By default, Docker requires a container restart to discover newly mounted filesystems under a configured bind-mount. Setting the bind-propagation option to `rslave` enables dynamic addition of sub-mounts while the container is running (Linux systems only). [See Docker Bind Mounts documentation for more information.](https://docs.docker.com/storage/bind-mounts/#configure-bind-propagation)
```bash
-v /plotdrives:/plotdrives:rslave
```

### Compressed Plots

There are a few environment variables that control compressed plot settings for Harvesters ran with chia-docker. The default settings leave compressed plot harvesting disabled, but it can be enabled.

See the [official documentation](https://docs.chia.net/farming-compressed-plots/#cli) for a description on what each of these settings do.

Compressed plot farming can be enabled by setting the following:

```bash
-e parallel_decompressor_count=1
-e decompressor_thread_count=1
```

And to use an nvidia GPU for plot decompression, set:

```bash
-e use_gpu_harvesting="true"
```

### Log level
To set the log level to one of CRITICAL, ERROR, WARNING, INFO, DEBUG, NOTSET
```bash
-e log_level="DEBUG"
```

### Peer Count
To set the peer_count and outbound_peer_count

for example to set both to 20 use
```bash
-e peer_count="20"
```

```bash
-e outbound_peer_count="20"
```

### UPnP
To disable UPnP support (enabled by default)
```bash
-e upnp="false"
```

### Log to file
Log file can be used by external tools like chiadog, etc. Enabled by default.

To disable log file generation, use
```bash
-e log_to_file="false"
```

### Docker Compose

```yaml
version: "3.6"
services:
  chia:
    container_name: chia
    restart: unless-stopped
    image: ghcr.io/chia-network/chia:latest
    ports:
      - 8444:8444
    environment:
      # Farmer Only
#     service: farmer-only
      # Harvester Only
#     service: harvester
#     farmer_address: 192.168.0.10
#     farmer_port: 8447
#     ca: /path/in/container
#     keys: generate
      # Harvester Only END
      # If you would like to add keys manually via mnemonic file
#     keys: /path/in/container
      # OR
      # Disable key generation on start
#     keys: 
      TZ: ${TZ}
      # Enable UPnP
#     upnp: "true"
      # Enable log file generation
#     log_to_file: "true"
    volumes:
      - /path/to/plots:/plots
      - /home/user/.chia:/root/.chia
#     - /home/user/mnemonic:/path/in/container
```

## CLI

You can run commands externally with venv (this works for most chia [CLI commands](https://github.com/Chia-Network/chia-blockchain/wiki/CLI-Commands-Reference))
```bash
docker exec -it chia venv/bin/chia plots add -d /plots
```

### Is it working?

You can see status from outside the container
```bash
$ docker exec -it chia venv/bin/chia farm summary
Farming status: Farming
Total chia farmed: xx
User transaction fees: xx
Block rewards: xx
Last height farmed: xxxxxxx
Local Harvester
   xxx plots of size: xx.xxx TiB
Plot count for all harvesters: xxx
Total size of plots: xx.xxx TiB
Estimated network space: 30.638 EiB
Expected time to win: x months and x weeks
Note: log into your key using 'chia wallet show' to see rewards for each key
```

Or via `chia peer`. Note that you have to specify your component.

```bash
docker exec -it chia venv/bin/chia peer -c {farmer|wallet|full_node|harvester|data_layer}
```

Or via `chia show -s`.

```bash
$ docker exec -it chia venv/bin/chia show -s
Network: mainnet    Port: 8444   RPC Port: 8555
Node ID: xxxxx
Genesis Challenge: xxxxx
Current Blockchain Status: Full Node Synced

Peak: Hash: xxxxx
      Time: Fri Jan 19 2024 17:52:44 CET                  Height:    4823454

Estimated network space: 30.639 EiB
Current difficulty: 11136
Current VDF sub_slot_iters: 574619648

  Height: |   Hash:
  4823454 | 7e66bd11e46801b25ac9237e300deff27a4750fc3bf4eb7e3c594b17faaf0b37
  4823453 | 9f5b68a52364c1afec48bc87d26bbba912c355e7f51c970f7bf89d068c762530
  4823452 | db3b5bb0e3d09fd398e2d9bd159c387f9ad280ec8719916ebb6c25c948834f9c
  4823451 | 5dd056960ec14da1c54fe295f33487e280f3e3c39eddced158ebb520b8215894
  4823450 | a3f5a3f61728b1f52e1ab7971b29d0c55b6bc8e2797ad826b780ada7a0f76a49
  4823449 | 052075e6b9881049c95c3ceeabed9160e5bfbf55a2b3b0768a743542ce88a3a3
  4823448 | 3e2b954d4eb782d1ce67eb7f17e9bf72843d17948ba181168dbc239c5e70acd2
  4823447 | 69539a9474c239280b6a6b4ab5be994e892c1b75c7bfb8967517e75ee5a65b12
  4823446 | 47ce031f46b2b0c9f90e90de4f9cab58054f356a7a3019b30c8f6292b86a5aae
  4823445 | 8c5d0254db6e304696d240dc70bad803ad227b861d68e65a3dc30c0aeef298f6

```

### Connect to testnet?

```bash
docker run -d --expose=58444 -e testnet=true --name chia ghcr.io/chia-network/chia:latest
```

### Connect remotely

Sometimes you may want to access Chia RPCs from outside of the container, or connect a GUI to a remote Chia farm. In those instances, you may need to configure the `self_hostname` key in the Chia config file.

By default this is set to `127.0.0.1` in chia-docker, but can be configured using the `self_hostname` environment variable, like so:

```bash
docker run -d -e self_hostname="0.0.0.0" --name chia ghcr.io/chia-network/chia:latest
```

This sets self_hostname in the config to `0.0.0.0`, which will allow you to access the Chia RPC from outside of the container (you will still need a copy of the private cert/key for the component you're attempting to access.)

#### Need a wallet?

To get new wallet, execute command and follow the prompts:

```bash
docker exec -it chia-farmer1 venv/bin/chia wallet show
```

## Building

```bash
docker build -t chia --build-arg BRANCH=latest .
```

## Healthchecks

The Dockerfile includes a HEALTHCHECK instruction that runs one or more curl commands against the Chia RPC API. In Docker, this can be disabled using an environment variable `-e healthcheck=false` as part of the `docker run` command. Or in docker-compose you can add it to your Chia service, like so:

```yaml
version: "3.6"
services:
  chia:
    ...
    environment:
      healthcheck: "false"
```

In Kubernetes, Docker healthchecks are disabled by default. Instead, readiness and liveness probes should be used, which can be configured in a Pod or Deployment manifest file like the following:

```yaml
livenessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - '/usr/local/bin/docker-healthcheck.sh || exit 1'
  initialDelaySeconds: 60
readinessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - '/usr/local/bin/docker-healthcheck.sh || exit 1'
  initialDelaySeconds: 60
```

See [Configure Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) for more information about configuring readiness and liveness probes for Kubernetes clusters. The `initialDelaySeconds` parameter may need to be adjusted higher or lower depending on the speed to start up on the host the container is running on.

## Simulator

`docker run -e service=simulator -v /local/path/to/simulator:/root/.chia/simulator ghcr.io/chia-network/chia:latest`

Mounts the simulator root to the provided local path to make the test plots and the mnemonic persistent. Mnemonic will be available at /local/path/to/simulator/mnemonic
