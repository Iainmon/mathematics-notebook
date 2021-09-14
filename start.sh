#!/bin/bash

# build command
# docker build --rm=false -t kobel/mathematics-notebook .

# better caching?
# DOCKER_BUILDKIT=1 docker build --rm=false -t kobel/mathematics-notebook:dev .

# Remote building 
# DOCKER_BUILDKIT=1 docker build --rm --force-rm -t kobel/ihaskell-notebook .
# DOCKER_BUILDKIT=1 docker build --rm --force-rm -t kobel/mathematics-notebook:dev .
# docker build --rm --force-rm -t kobel/mathematics-notebook:dev .

# run command
docker run --rm -it \
     -p 8881:8888 \
     -e JUPYTER_ENABLE_LAB=yes \
     -e RESTARTABLE=yes \
     -e CHOWN_HOME=yes \
     -e NB_USER=kodel \
     -v /home/iainmoncrief/labfiles:/home/jovyan/work \
     --name kobel_mathematics_notebook_ihaskell_test \
     kobel/mathematics-notebook:dev \
     jupyter lab \
     --NotebookApp.token=''\
     --ServerApp.token='' \
     --ServerApp.port=8888 \
     --NotebookApp.port=8888 \
     --ServerApp.root_dir='/home/jovyan/work' \
     --NotebookApp.notebook_dir='/home/jovyan/work'
     # ghcr.io/iainmon/mathematics-notebook:main
