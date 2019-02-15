#!/bin/bash

set -e

if [[ "x${CI_COMMIT_TAG}" == "x" ]] ; then
    sed -i -e 's;style\ \=\ pep440;style\ \=\ ci_wheel_builder;g' setup.cfg
fi

set -u

# since we're in a d-in-d setup this needs to a be a path shared from the real host
BUILDER_WHEELHOUSE=${SHARED_PATH}
REPODIR=${HOME}/wheels
PYMOR_ROOT="$(cd "$(dirname ${BASH_SOURCE[0]})" ; cd ../../ ; pwd -P )"
cd "${PYMOR_ROOT}"

source ./.ci/gitlab/init_sshkey.bash
init_ssh

set -x
mkdir -p ${BUILDER_WHEELHOUSE}
git clone git@github.com:pymor/wheels.pymor.org ${REPODIR}
for py in 3.6 3.7 ; do
    BUILDER_IMAGE=pymor/wheelbuilder:py${py}
    git clean -xdf
    docker pull ${BUILDER_IMAGE} 1> /dev/null
    docker run --rm  -t -e LOCAL_USER_ID=$(id -u)  \
        -v ${BUILDER_WHEELHOUSE}:/io/wheelhouse \
        -v ${PYMOR_ROOT}:/io/pymor ${BUILDER_IMAGE} /usr/local/bin/build-wheels.sh #1> /dev/null
done

cp ${PYMOR_ROOT}/.ci/docker/deploy_checks/Dockerfile ${BUILDER_WHEELHOUSE}
for os in debian_stable debian_testing centos_7 ; do
    docker build --build-arg tag=${os} ${BUILDER_WHEELHOUSE}
done

for py in 3.6 3.7 ; do
    ${REPODIR}/add_wheels.py ${CI_COMMIT_REF_NAME} ${BUILDER_WHEELHOUSE}/pymor*manylinux*.whl
done

set +u

cd ${REPODIR}
git config user.name "pyMOR Bot"
git config user.email "travis@pymor.org"
git commit -am "[deploy] wheels for ${CI_COMMIT_SHA}"
git pull --rebase
git push