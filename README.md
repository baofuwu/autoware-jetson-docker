# Autoware-Jetson
Create a Docker image for Jetson of Autoware. Also, enable Autoware to be started on the container.

## Install
```bash
#!/bin/bash
git clone --recursive https://github.com/shikishima-TasakiLab/autoware-jetson-docker.git Autoware-Jetson
```

## How to use

### Creating a Docker image

Build the Docker image with the following command.
```bash
#!/bin/bash
./Autoware-Jetson/docker/build-docker.sh
```
|Option       |Parameters|Explanation                                |Default value  |Example         |
|-----------------|----------|------------------------------------|--------|-----------|
|`-h`, `--help`   |None      |Show help                        |none    |`-h`       |
|`-v`, `--version`|VERSION   |Specify Autoware version (> = 1.12.0)|`1.13.0`|`-v 1.12.0`|

### Start Docker container

1. Start the Docker container with the following command.
    ```bash
    #!/bin/bash
    ./Autoware-Jetson/docker/run-docker.sh
    ```
    |Option       |Parameters|Explanation                                |Default value    |Example                  |
    |-----------------|----------|---------------------------------|----------|--------------------|
    |`-h`, `--help`   |none      |Show help                       |none      |`-h`                |
    |`-l`, `--launch` |{on\|off} |Launch runtime_manager      |`on`      |`-l off`            |
    |`-p`, `--param`  |FILE      |Specify the Autoware configuration file to read |`./docker/autoware-param/param_init.yaml`|`-p robot_1.yaml`|
    |`-s`, `--save`   |FILE      |Specify the save destination of the Autoware configuration file |none      |`-s robot_1.yaml`|
    |`-n`, `--name`   |NAME      |Specify the name of the container               |`autoware`|`-n autoware-master`|

2. When using another ROS node with Autoware's Docker container, execute the following command in another terminal.
    ```bash
    #!/bin/bash
    ./Autoware-Jetson/docker/exec-docker.sh
    ```
    |Option       |Parameters|Explanation        |Default value|Example                  |
    |-----------------|----------|--------------------------|------|--------------------|
    |`-h`, `--help`   |none      |Show help              |none  |`-h`                |

