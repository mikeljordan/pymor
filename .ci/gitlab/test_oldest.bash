#!/bin/bash

THIS_DIR="$(cd "$(dirname ${BASH_SOURCE[0]})" ; pwd -P )"
source ${THIS_DIR}/common_test_setup.bash

# keep PIP_CONFIG_FILE or else pip config doesn't use the right mirror
SUDO="sudo --preserve-env=PIP_CONFIG_FILE"
# _downgrade_ packages to what's avail in the oldest mirror
${SUDO} python -m pip uninstall -y -r requirements-optional.txt
${SUDO} python -m pip uninstall -y -r requirements-ci.txt
${SUDO} python -m pip uninstall -y -r requirements.txt
# for some reason pip does not remove the whole mdist-info dir of mpi4py
# essentially breaking any attempt at reinstallation
${SUDO} rm -rf /usr/local/lib/python3.*/site-packages/mpi4py-*.dist-info
${SUDO} python -m pip install -U -r requirements.txt
${SUDO} python -m pip install -U -r requirements-ci.txt
${SUDO} python -m pip install -U -r requirements-optional.txt

python -m pip freeze
# this runs in pytest in a fake, auto numbered, X Server
xvfb-run -a py.test ${COMMON_PYTEST_OPTS}
coverage xml
