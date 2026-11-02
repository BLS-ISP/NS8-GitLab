#!/bin/bash

#
# Copyright (C) 2023 Nethesis S.r.l.
# SPDX-License-Identifier: GPL-3.0-or-later
#

LEADER_NODE=$1
IMAGE_URL=$2
SCENARIO=${3:-install}
STABLE_URL=${4:-}
SSH_KEYFILE=${SSH_KEYFILE:-$HOME/.ssh/id_rsa}

ssh_key="$(cat $SSH_KEYFILE)"

podman run -i \
    -v .:/home/pwuser/ns8-module:z \
    --volume=site-packages:/home/pwuser/.local/lib/python3.8/site-packages:Z \
    --name rf-core-runner ghcr.io/marketsquare/robotframework-browser/rfbrowser-stable:v10.0.3 \
    bash -l -s <<EOF
    set -e
    echo "$ssh_key" > /home/pwuser/ns8-key
    set -x
    pip install -q -r /home/pwuser/ns8-module/tests/pythonreq.txt
    mkdir -p ~/outputs
    cd /home/pwuser/ns8-module
    exec robot -v NODE_ADDR:${LEADER_NODE} \
        -v IMAGE_URL:${IMAGE_URL} \
        -v SCENARIO:${SCENARIO} \
        -v STABLE_URL:${STABLE_URL} \
        -v SSH_KEYFILE:/home/pwuser/ns8-key \
        --name gitlab-${SCENARIO} \
        --skiponfailure unstable \
        -d ~/outputs /home/pwuser/ns8-module/tests/
EOF

tests_res=$?

podman cp rf-core-runner:/home/pwuser/outputs tests/
podman stop rf-core-runner
podman rm rf-core-runner

exit ${tests_res}
