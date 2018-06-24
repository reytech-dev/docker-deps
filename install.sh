#!/usr/bin/env bash

## Variables
CURRENT_DIR=`pwd`
BIN_PATH=${CURRENT_DIR}"/bin"
COMMAND_APPENDIX="-docker"

declare -A LIST
LIST=(
    ["python"]=external:python
    ["node"]=external:node
    ["gulp"]=local:dockerfiles/gulp
    ["npm"]=external:node
    ["express"]=local:dockerfiles/express
    ["yarn"]=external:node
    ["php"]=external:php
    ["grunt"]=local:dockerfiles/grunt
)

## Functions
writeGreenOutput() {
    echo -e "\033[0;32m"${1}"\033[0m"
}

writeRedOutput() {
    echo -e "\033[0;31m"${1}"\033[0m"
}

createBinDir() {
    writeGreenOutput "Creating bin-directory"
    mkdir -p ${BIN_PATH}
}

dockerExists() {
    # Returns the binary path if it is available (same as which() but portable)
    # Details:
    ## Redirect command output (0=stdout to /dev/null 2=stderr to 1=stdout)
    ## Execute echo command only when first command failed (exit status not 0)
    ## Redirect echo into stderr
    ## Exit script with exit code 1
    command -v docker >/dev/null 2>&1 || { writeRedOutput "Docker must be installed. Aborting." >&2; exit 1; }
}

dockerTest() {
    # Returns the version details of current installed docker
    # Details:
    ## Redirect command output (0=stdout to /dev/null 2=stderr to 1=stdout)
    ## Execute echo command only when first command failed (exit status not 0)
    ## Redirect echo into stderr
    ## Exit script with exit code 1
    docker -v >/dev/null 2>&1 || { writeRedOutput "Docker must be usable with your current user. Aborting." >&2; exit 1; }
}

installCommand() {
    COMMAND_NAME=${1}
    IMAGE_NAME=${2}
    # Current working directory gets mounted as volume into docker
    # Current working directory gets used as workdir, so files can get properly used
    writeGreenOutput "Writing \"bin\" for use"
    ## Write the file for /usr/bin/ dir (python2.7)
    echo -e "#!/usr/bin/env bash\ndocker run --rm --name ${COMMAND_NAME}-bin -u \`id -u\`:\`id -g\` -v \`pwd\`:/data -w /data ${IMAGE_NAME} ${COMMAND_NAME} \"\$@\"" > ${BIN_PATH}/${COMMAND_NAME}
    writeGreenOutput "Make it executable"
    ## Add execute permission for files
    chmod +x ${BIN_PATH}/${COMMAND_NAME}
    writeGreenOutput "Creating symlink into /usr/bin/. I'm gonna ask for the sudo password."
    ## Create symlinks into /usr/bin/ dir
    sudo ln -sf ${BIN_PATH}/${COMMAND_NAME} /usr/bin/${IMAGE_NAME}${COMMAND_APPENDIX}
    writeGreenOutput "Use ${COMMAND_NAME} with ${IMAGE_NAME}${COMMAND_APPENDIX}"
}

getImage() {
    IMAGE_NAME=${1}
    SOURCE=${2}

    if [[ ${SOURCE} =~ "external" ]]; then
        remotePull $(echo ${SOURCE} | sed -e "s/external://g")
    elif [[ "${SOURCE}" =~ "local" ]]; then
        localBuild ${IMAGE_NAME} $(echo ${SOURCE} | sed -e "s/local://g")
    fi
}

remotePull() {
    IMAGE_NAME=${1}
    writeGreenOutput "Pulling ${IMAGE_NAME} image"
    ## Pull python docker image from docker hub
    docker pull ${IMAGE_NAME}
}

localBuild() {
    IMAGE_NAME=${1}
    SOURCE=${2}
    # Change into dockerfiles subdir for current image
    cd ${CURRENT_DIR}"/"${SOURCE}
    docker build -t ${IMAGE_NAME} .
    # Change back into source directory
    cd ${CURRENT_DIR}
}

testCommand() {
    COMMAND_NAME=${1}${COMMAND_APPENDIX}
    writeGreenOutput "Test command ${COMMAND_NAME} image"
    ${COMMAND_NAME} --version
}

cleanUp() {
    # Remove old files for avoiding conflicts
    # Perhaps we can remove this for later updates
    writeGreenOutput "Run cleanup and delete old files."
    ## Check if bin dir is existing
    if [ -d ${BIN_PATH} ]; then
        rm -rf ${BIN_PATH}
    fi
}

## Logic

cleanUp
createBinDir
dockerExists
dockerTest

# Pull and install docker images
## Indirect expansion
for i in ${!LIST[*]}; do
    getImage ${i} ${LIST[${i}]}
    installCommand ${i} $(echo ${SOURCE} | sed -e "s/external://g" | sed -e "s/dockerfiles\///g")
done

# Test commands
for i in ${!LIST[*]}; do
    testCommand ${i}
done