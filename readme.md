#Official Chia Docker Container


### Startup
Docker exec -it chia:latest /bin/bash

starting with a chia config file modify the line

```self_hostname: &self_hostname "localhost"``` to read ```self_hostname: &self_hostname "127.0.0.1"```

if you are starting an introducer you also want to modify this section

 ```harvester:
  # The harvester server (if run) will run on this port
  port: 8448
  farmer_peer:
    host: *self_hostname
    port: 8447```

to include the proper host and port for your remote farmer node or container.

Once your configuration is right. you can start chia as normal

```chia start farmer```
