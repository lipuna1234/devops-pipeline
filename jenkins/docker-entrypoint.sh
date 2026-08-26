#!/bin/bash
set -e

# The Docker socket is mounted from the Docker host and its group ID can vary.
# Detect the socket GID and add the Jenkins user to the matching group.
if [ -S /var/run/docker.sock ]; then
    DOCKER_GID="$(stat -c '%g' /var/run/docker.sock)"

    if getent group "$DOCKER_GID" >/dev/null 2>&1; then
        DOCKER_GROUP="$(getent group "$DOCKER_GID" | cut -d: -f1)"
    else
        DOCKER_GROUP="dockerhost"
        groupadd -g "$DOCKER_GID" "$DOCKER_GROUP"
    fi

    usermod -aG "$DOCKER_GROUP" jenkins
fi

# Start Jenkins as the normal jenkins user.
exec gosu jenkins /usr/bin/tini -- /usr/local/bin/jenkins.sh
