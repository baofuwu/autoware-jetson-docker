#!/bin/bash
BUILD_DIR=$(dirname $(readlink -f $0))
AUTOWARE_VERSION="1.14.0"
CURRENT_DIR=$(pwd)
USER_ID=$(id -u)
PROG_NAME=$(basename $0)

ntr_arr=( $(echo $(cat /etc/nv_tegra_release) | tr -s ',' ' ') )
MAJOR_VERSION=${ntr_arr[1]}
MINOR_VERSION=${ntr_arr[4]}
if [[ ${MINOR_VERSION} == '5.1' ]]; then
    MINOR_VERSION='5.0'
fi

function usage_exit {
  cat <<_EOS_ 1>&2
  Usage: $PROG_NAME [OPTIONS...]
  OPTIONS:
    -h, --help Show this help
    -v, --version AUTOWARE_VERSION Specify the version of Autoware (> = 1.12.0)
_EOS_
    cd ${CURRENT_DIR}
    exit 1
}

while (( $# > 0 )); do
    if [[ $1 == "--help" ]] || [[ $1 == "-h" ]]; then
        usage_exit
    elif [[ $1 == "--version" ]] || [[ $1 == "-v" ]]; then
        if [[ $2 == -* ]]; then
            echo "invalid parameter"
            usage_exit
        else
            AUTOWARE_VERSION=$2
        fi
        shift 2
    else
        echo "invalid parameter： $1"
        usage_exit
    fi
done

ROS_IMAGE="jetson/ros"
ROS_TAG="${MAJOR_VERSION,,}.${MINOR_VERSION}-melodic"
IMAGE_EXIST=$(docker images | grep ${ROS_IMAGE} | grep ${ROS_TAG})
if [[ -z ${IMAGE_EXIST} ]]; then
    ${BUILD_DIR}/src-ros/docker/build-docker.sh
    if [[ $? != 0 ]]; then
        echo "Interrupted due to an error."
        cd ${CURRENT_DIR}
        exit 1
    fi
fi

XSOCK="/tmp/.X11-unix"
XAUTH="/tmp/.docker.xauth"

HOST_SRC=${BUILD_DIR}/src-autoware

DOCKER_VOLUME="${DOCKER_VOLUME} -v ${XSOCK}:${XSOCK}:rw"
DOCKER_VOLUME="${DOCKER_VOLUME} -v ${XAUTH}:${XAUTH}:rw"
DOCKER_VOLUME="${DOCKER_VOLUME} -v ${HOST_SRC}:/tmp/src-autoware:rw"

DOCKER_ENV="-e USER_ID=${USER_ID}"
DOCKER_ENV="${DOCKER_ENV} -e XAUTHORITY=${XAUTH}"
DOCKER_ENV="${DOCKER_ENV} -e DISPLAY=$DISPLAY"
DOCKER_ENV="${DOCKER_ENV} -e TERM=xterm-256color"
DOCKER_ENV="${DOCKER_ENV} -e QT_X11_NO_MITSHM=1"

DOCKER_NET="host"

CONTAINER_NAME="autoware-build"
CONTAINER_CMD="/bin/bash /tmp/src-autoware/build_autoware.${AUTOWARE_VERSION}.sh"

touch ${XAUTH}
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f ${XAUTH} nmerge -

CONTAINER_EXIST=$(docker ps -a | grep ${CONTAINER_NAME})
if [[ -n ${CONTAINER_EXIST} ]]; then
    docker rm ${CONTAINER_NAME}
fi

# xhost +

docker run \
    -it \
    # --runtime nvidia \
    --gpus all \
    --privileged \
    --name ${CONTAINER_NAME} \
    --net ${DOCKER_NET} \
    ${DOCKER_ENV} \
    ${DOCKER_VOLUME} \
    ${ROS_IMAGE}:${ROS_TAG} \
    ${CONTAINER_CMD}

if [[ $? != 0 ]]; then
    echo "Interrupted due to an error."
    cd ${CURRENT_DIR}
    exit 1
fi

CONTAINER_ID=$(docker ps -a | grep ${ROS_IMAGE}:${ROS_TAG} | grep ${CONTAINER_NAME})
CONTAINER_ID=${CONTAINER_ID:0:12}

docker commit \
    -a "shikishima-TasakiLab" \
    -m "Autoware for Jetson" \
    -c 'ENTRYPOINT ["/tmp/entrypoint.sh"]' \
    ${CONTAINER_ID} \
    jetson/autoware:${MAJOR_VERSION,,}.${MINOR_VERSION}-${AUTOWARE_VERSION}

CONTAINER_EXIST=$(docker ps -a | grep ${CONTAINER_NAME})
if [[ -n ${CONTAINER_EXIST} ]]; then
    docker rm ${CONTAINER_NAME}
fi

