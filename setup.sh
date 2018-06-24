#!/usr/bin/env bash

## Variables
CURRENT_DIR=`pwd`
DOCKER_BIN_PATH=${CURRENT_DIR}"/bin"
COMMAND_APPENDIX="-docker"
LOCAL_BIN_PATH="/usr/bin"
# Declare array with list by docker container replaced bins
declare -A LIST
LIST=(
    ["python"]=external:python
    ["node"]=external:node:latest
    ["gulp"]=local:dockerfiles/gulp
    ["npm"]=external:node:latest
    ["express"]=local:dockerfiles/express
    ["yarn"]=external:node:latest
    ["php"]=external:php
    ["grunt"]=local:dockerfiles/grunt
)

## Functions

# Give green cli feedback
writeGreenOutput() {
    echo -e "\033[0;32m"${1}"\033[0m"
}

# Give red cli feedback
writeRedOutput() {
    echo -e "\033[0;31m"${1}"\033[0m"
}

# Create bin/ directory if not exists
createBinDir() {
    writeGreenOutput "Creating bin-directory"
    mkdir -p ${DOCKER_BIN_PATH}
}

# Returns the binary path if it is available (same as which() but portable)
dockerExists() {
    # Details:
    # Redirect command output (0=stdout to /dev/null 2=stderr to 1=stdout)
    # Execute echo command only when first command failed (exit status not 0)
    # Redirect echo into stderr
    # Exit script with exit code 1
    command -v docker >/dev/null 2>&1 || { writeRedOutput "Docker must be installed. Aborting." >&2; exit 1; }
}

# Check if docker command is useable
dockerTest() {
    # Details:
    # Redirect command output (0=stdout to /dev/null 2=stderr to 1=stdout)
    # Execute echo command only when first command failed (exit status not 0)
    # Redirect echo into stderr
    # Exit script with exit code 1
    docker run hello-world >/dev/null 2>&1 || { writeRedOutput "Docker must be usable with your current user. Aborting." >&2; exit 1; }
}

# Create bin replacement bash script and link it into LOCAL_BIN_PATH dir
installCommand() {
    # The command name in the docker container
    COMMAND_NAME=${1}
    # Image name which is used in the docker bash script
    IMAGE_NAME=${2}
    # Full name for command which is used on the host system
    FULL_COMMAND_NAME=${COMMAND_NAME}${COMMAND_APPENDIX}
    # Current working directory gets mounted as volume into docker
    # Current working directory gets used as workdir, so files can get properly used
    writeGreenOutput "Writing \"bin\" for use"
    # Write the file for LOCAL_BIN_PATH/
    echo -e "#!/usr/bin/env bash\ndocker run --rm --name ${COMMAND_NAME}-bin -u \`id -u\`:\`id -g\` -v \`pwd\`:/data -w /data ${IMAGE_NAME} ${COMMAND_NAME} \"\$@\"" > ${DOCKER_BIN_PATH}/${COMMAND_NAME}
    writeGreenOutput "Make it executable"
    # Add execute permission for file
    chmod +x ${DOCKER_BIN_PATH}/${COMMAND_NAME} || { writeRedOutput "File not found, I guess? (${DOCKER_BIN_PATH}/${COMMAND_NAME})" >&2; exit 1; }
    writeGreenOutput "Creating symlink into ${LOCAL_BIN_PATH}/. I'm gonna ask for the sudo password."
    # Create symlink into LOCAL_BIN_PATH/
    sudo ln -sf ${DOCKER_BIN_PATH}/${COMMAND_NAME} ${LOCAL_BIN_PATH}"/"${FULL_COMMAND_NAME} || { writeRedOutput "Command couldn't get installed (${FULL_COMMAND_NAME})" >&2; exit 1; }
    writeGreenOutput "Use ${COMMAND_NAME} with ${FULL_COMMAND_NAME}"
}

# Prepare local environment and pull or build images
getImage() {
    # Name of docker image
    IMAGE_NAME=${1}
    # Source of docker image. If local its including the path to the dockerfile
    SOURCE=${2}

    if [[ ${SOURCE} =~ "external" ]]; then
        remotePull $(echo ${SOURCE} | sed -e "s/external://g")
    elif [[ "${SOURCE}" =~ "local" ]]; then
        localBuild ${IMAGE_NAME} $(echo ${SOURCE} | sed -e "s/local://g")
    fi
}

# Pull docker image from remote docker repository
remotePull() {
    # Name of docker image
    IMAGE_NAME=${1}
    writeGreenOutput "Pulling ${IMAGE_NAME} image"
    # Pull python docker image from docker hub
    docker pull ${IMAGE_NAME} || { writeRedOutput "Couldn't pull image ${IMAGE_NAME}" >&2; exit 1; }
}

# Build docker image from local dockerfile
localBuild() {
    # Name of docker image
    IMAGE_NAME=${1}
    SOURCE=${2}
    # Change into dockerfiles subdir for current image
    cd ${CURRENT_DIR}"/"${SOURCE}
    # Build image based on found Dockerfile
    docker build -t ${IMAGE_NAME} . || { writeRedOutput "Couldn't build image ${IMAGE_NAME}" >&2; exit 1; }
    # Change back into source directory
    cd ${CURRENT_DIR}
}

# Test if command is usable by calling it with --version argument
testCommand() {
    # Full command name includes the defined appendix
    FULL_COMMAND_NAME=${1}${COMMAND_APPENDIX}
    writeGreenOutput "Test command ${FULL_COMMAND_NAME} image"
    # Execute command and check current available version
    ${FULL_COMMAND_NAME} --version || { writeRedOutput "Command ${FULL_COMMAND_NAME} failed" >&2; exit 1; }
}

# Delete bin dir to remove all created bash scripts
cleanUpDir() {
    # Remove old files for avoiding conflicts
    # Perhaps we can remove this for later updates
    writeGreenOutput "Run cleanup and delete old files."
    # Check if bin dir is existing
    if [ -d ${DOCKER_BIN_PATH} ]; then
        rm -rf ${DOCKER_BIN_PATH}
    fi
}

# Delete symlinks to our created bash scripts
cleanUpSymlink() {
    # Full command name includes the defined appendix
    FULL_COMMAND_NAME=${1}${COMMAND_APPENDIX}
    writeGreenOutput "Remove command ${FULL_COMMAND_NAME}"
    sudo rm -f ${LOCAL_BIN_PATH}"/"${FULL_COMMAND_NAME} || { writeRedOutput "Command ${FULL_COMMAND_NAME} not found" >&2; exit 1; }
}

cleanUpImage() {
    IMAGE_NAME=${1}
    if [[ "$(docker images -q ${IMAGE_NAME} 2> /dev/null)" != "" ]]; then
        writeGreenOutput "Remove image ${IMAGE_NAME}"
        docker rmi ${IMAGE_NAME} || { writeRedOutput "Image ${IMAGE_NAME} not found" >&2; exit 1; }
    fi
}

## Logic

if [ "$1" == "install" ]; then
    cleanUpDir
    createBinDir
    dockerExists
    dockerTest

    # Pull and install docker images
    # Indirect expansion
    for i in ${!LIST[*]}; do
        # Pull Image
        getImage ${i} ${LIST[${i}]}
        # Install bash script into LOCAL_BIN_PATH
        installCommand ${i} $(echo ${LIST[${i}]} | sed -e "s/local://g" | sed -e "s/external://g" | sed -e "s/dockerfiles\///g")
    done

    # Test commands
    for i in ${!LIST[*]}; do
        testCommand ${i}
    done
elif [ "$1" == "uninstall" ]; then
    # Remove commands
    for i in ${!LIST[*]}; do
        # Delete symlink into LOCAL_BIN_PATH
        cleanUpSymlink ${i}
        # Remove image from local repository
        cleanUpImage $(echo ${LIST[${i}]} | sed -e "s/local://g" | sed -e "s/external://g" | sed -e "s/dockerfiles\///g")
    done
    cleanUpDir
else
    echo "Usage: bash setup.sh install|uninstall"
fi