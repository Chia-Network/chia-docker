# Official Chia Docker Container

## Basic Startup
```
docker run --name <container-name> -d ghcr.io/chia-network/chia:latest
(optional -v /path/to/plots:plots)
```

## Configuration

You can modify the behavior of your Chia container by setting specific environment variables.

To use your own keys pass
```
-e keys="twenty four words"
```

To start a farmer only node pass
```
-e farmer="true"
```

To start a harvester only node pass
```
-e harvester="true" -e farmer_address="addres.of.farmer" -e farmer_port="portnumber"
```

#### or run the commands externally with venv
```
docker exec -it chia venv/bin/chia keys add
docker exec -it chia venv/bin/chia plots add -d /plots
```

#### status from outside the container
```
docker exec -it chia venv/bin/chia show -s -c
```

#### Connect to testnet?
```
docker run -d --expose=58444 --expose=8555 --name <container-name> ghcr.io/chia-network/chia:latest
```

#### Need a wallet?
```
docker exec -it chia-farmer1 venv/bin/chia wallet show (follow the prompts)
```
