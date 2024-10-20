# syntax=docker/dockerfile:1

ARG NODE_VERSION=22.9.0
ARG OS_VERSION_CODENAME=bookworm
ARG DOCKER_IMAGE_INDEX_DIGEST=sha256:cbe2d5f94110cea9817dd8c5809d05df49b4bd1aac5203f3594d88665ad37988
ARG DOCKER_IMAGE=node:${NODE_VERSION}-${OS_VERSION_CODENAME}@${DOCKER_IMAGE_INDEX_DIGEST}

ARG USERNAME=node
ARG WORKDIR=/workspaces/vscode-theme-darcula-void

ARG TASKFILE_VERSION=3.39.2

# ------------------------------------------------------------------------------
# BASE
# ------------------------------------------------------------------------------
FROM $DOCKER_IMAGE AS base

ARG USERNAME

# Install packages
RUN apt-get update -qq \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
	sudo \
	net-tools \
	lsb-release \
	&& apt-get clean \
	&& rm -rf /var/cache/apt/archives/* \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
	&& truncate -s 0 /var/log/*log

# Add add sudo support for non-root user
RUN echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
	chmod 0440 /etc/sudoers.d/$USERNAME

# ------------------------------------------------------------------------------
# BUILDER-ENV
# ------------------------------------------------------------------------------
FROM base AS builder-env

ARG USERNAME
ARG TASKFILE_VERSION

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0

USER root

# Install taskfile
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- \
	-b /usr/local/bin -d v$TASKFILE_VERSION

# Corepack
RUN corepack enable

# ------------------------------------------------------------------------------
# PROJECT-ENV
# ------------------------------------------------------------------------------
FROM builder-env AS project-env

ARG USERNAME
ARG HOME
ARG WORKDIR

USER $USERNAME
WORKDIR $WORKDIR

ENV NODE_ENV=production

# Install packages
RUN --mount=type=bind,source=package.json,target=package.json \
	--mount=type=bind,source=yarn.lock,target=yarn.lock \
	--mount=type=cache,target=$HOME/.yarn \
	yarn install --immutable

COPY --chown=$USERNAME:$USERNAME . $WORKDIR

# ------------------------------------------------------------------------------
# RUNTIME
# ------------------------------------------------------------------------------
FROM project-env AS runtime

ARG USERNAME
ARG WORKDIR

USER $USERNAME
WORKDIR $WORKDIR

CMD ["/bin/bash"]
