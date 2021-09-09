ARG BASE_CONTAINER=jupyter/scipy-notebook:lab-3.1.10
ARG IHASKELL_CONTAINER=gibiansky/ihaskell:latest
ARG IHASKELL_NB_CONTAINER=ghcr.io/jamesdbrock/ihaskell-notebook:master
FROM $IHASKELL_CONTAINER
FROM $IHASKELL_NB_CONTAINER
FROM $BASE_CONTAINER

ARG CONDA_ENV=base
ARG APT_COMMAND=apt-get


LABEL maintainer="Iain Moncrief"
LABEL workdir="${WORK_DIR}"

### Begin sage

USER root

# Sage pre-requisites and jq for manipulating json
RUN $APT_COMMAND update && \
    $APT_COMMAND install -y --no-install-recommends \
    dvipng \
    ffmpeg \
    imagemagick \
    texlive \
    tk tk-dev \
    jq && \
    rm -rf /var/lib/apt/lists/*


ARG SAGE_VERSION=9.3.*
ARG SAGE_PYTHON_VERSION=3.9.*
ARG SAGE_CONDA_ENV=base

USER $NB_UID

# Initialize conda for shell interaction
RUN conda init bash

# Install Sage conda environment
# RUN conda install --quiet --yes -n base -c conda-forge widgetsnbextension && \
#     conda create --quiet --yes -n sage -c conda-forge sage=$SAGE_VERSION python=$SAGE_PYTHON_VERSION && \
#     conda clean --all -f -y && \
#     npm cache clean --force && \
#     fix-permissions $CONDA_DIR && \
#     fix-permissions /home/$NB_USER
ARG MAMBA_OR_CONDA=mamba

# ARG CACHING_ARGS=--freeze-installed
ARG CACHING_ARGS=

# Better conda caching. Without silencing.
RUN conda install --yes -n $CONDA_ENV -c conda-forge \
    mamba

RUN $MAMBA_OR_CONDA install $CACHING_ARGS --yes -n $CONDA_ENV -c conda-forge \
    conda-lock \
    widgetsnbextension
RUN $MAMBA_OR_CONDA install -c conda-forge conda-lock

RUN $MAMBA_OR_CONDA create --yes -n $SAGE_CONDA_ENV -c conda-forge || echo "0"
RUN $MAMBA_OR_CONDA install $CACHING_ARGS --yes -n $SAGE_CONDA_ENV -c conda-forge \
    sage=$SAGE_VERSION \
    python=$SAGE_PYTHON_VERSION || \
    echo "Something went wrong." && exit "0"

# RUN conda create --freeze-installed --yes -n base -c conda-forge sage=$SAGE_VERSION python=$SAGE_PYTHON_VERSION
# RUN conda install --freeze-installed --yes -n sage -c conda-forge sage=$SAGE_VERSION python=$SAGE_PYTHON_VERSION

RUN $MAMBA_OR_CONDA clean --all -f -y
RUN npm cache clean --force
RUN fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER



# RUN set -x \
# && sed -Ei 's|^(DPkg::Pre-Install-Pkgs .*)|#\1|g' /etc/apt/apt.conf.d/70debconf \
# && apt-get update \
# && apt-get upgrade -y

# # Sage pre-requisites and jq for manipulating json
# # RUN apt update -y && \
# RUN apt-get update -y && \
#     # apt-get install -y --no-install-recommends apt-utils && \
#     apt-get install -y --no-install-recommends \
#     # apt upgrade -y &&\
#     # apt install -y --no-install-recommends \
#     # nodejs \
#     dvipng \
#     ffmpeg \
#     imagemagick \
#     texlive \
#     tk tk-dev \
#     jq && \
#     # apt upgrade -y &&\
#     # rm -rf /var/lib/apt/lists/*
#     apt-get clean && rm -rf /var/lib/apt/lists/*

# USER $NB_UID

# # Initialize conda for shell interaction
# RUN conda init bash

# # Install Sage conda environment
# RUN conda install --quiet --yes -n base -c conda-forge widgetsnbextension && \
#     conda create --quiet --yes -n sage -c conda-forge sage=$SAGE_VERSION python=$SAGE_PYTHON_VERSION && \
#     conda clean --all -f -y && \
#     npm cache clean --force && \
#     fix-permissions "${CONDA_DIR}" && \
#     fix-permissions "/home/${NB_USER}"

# Install sagemath kernel and extensions using conda run:
#   Create jupyter directories if they are missing
#   Add environmental variables to sage kernal using jq
RUN echo ' \
        from sage.repl.ipython_kernel.install import SageKernelSpec; \
        SageKernelSpec.update(prefix=os.environ["CONDA_DIR"]); \
    ' | conda run -n $SAGE_CONDA_ENV sage && \
    echo ' \
        cat $SAGE_ROOT/etc/conda/activate.d/sage-activate.sh | \
            grep -Po '"'"'(?<=^export )[A-Z_]+(?=)'"'"' | \
            jq --raw-input '"'"'.'"'"' | jq -s '"'"'.'"'"' | \
            jq --argfile kernel $SAGE_LOCAL/share/jupyter/kernels/sagemath/kernel.json \
            '"'"'. | map(. as $k | env | .[$k] as $v | {($k):$v}) | add as $vars | $kernel | .env= $vars'"'"' > \
            $CONDA_DIR/share/jupyter/kernels/sagemath/kernel.json \
    ' | conda run -n $SAGE_CONDA_ENV sh && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install sage's python kernel
RUN echo ' \
        ls /opt/conda/envs/sage/share/jupyter/kernels/ | \
            grep -Po '"'"'python\d'"'"' | \
            xargs -I % sh -c '"'"' \
                cd $SAGE_LOCAL/share/jupyter/kernels/% && \
                cat kernel.json | \
                    jq '"'"'"'"'"'"'"'"' . | .display_name = .display_name + " (sage)" '"'"'"'"'"'"'"'"' > \
                    kernel.json.modified && \
                mv -f kernel.json.modified kernel.json && \
                ln  -s $SAGE_LOCAL/share/jupyter/kernels/% $CONDA_DIR/share/jupyter/kernels/%_sage \
            '"'"' \
    ' | conda run -n $SAGE_CONDA_ENV sh && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER



### End Sage

LABEL STAGE="SAGEMATH Complete."

USER root
LABEL USER="root"

USER $NB_UID
LABEL USER=$NB_USER

RUN $MAMBA_OR_CONDA install $CACHING_ARGS --yes -n $CONDA_ENV \
# ihaskell-widgets needs ipywidgets
    'ipywidgets' && \
# ihaskell-hvega doesn't need an extension. https://github.com/jupyterlab/jupyter-renderers
#    'jupyterlab-vega3' && \
    conda clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

RUN conda env export -n $CONDA_ENV --no-builds --file /home/$NB_USER/work/kodel_environment.yml && \
    conda env export -n $SAGE_CONDA_ENV --no-builds --file /home/$NB_USER/work/sage_environment.yml && \
    conda-lock lock -f /home/$NB_USER/work/kodel_environment.yml -p linux-64 --filename-template "kodel-base-{platform}.lock" && \
    conda-lock lock -f /home/$NB_USER/work/sage_environment.yml -p linux-64 --filename-template "kodel-sage-{platform}.lock"

