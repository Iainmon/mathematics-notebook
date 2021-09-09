#!/bin/bash

# build command
docker build --rm=false -t kobel/ihaskell-notebook:test1 .
# better caching?
DOCKER_BUILDKIT=1 docker build --rm=false -t kobel/ihaskell-notebook:test1 .
# Remote building 
DOCKER_BUILDKIT=1 docker build --rm --force-rm -t kobel/ihaskell-notebook .

# run command
docker run -it --rm \
     -p 8881:8888 \
     -e JUPYTER_ENABLE_LAB=yes \
     -e RESTARTABLE=yes \
     -e CHOWN_HOME=yes \
     -e NB_USER=kodel \
     -v /home/iainmoncrief/labfiles:/home/jovyan/work \
     --name kobel_image_test \
     kobel/ihaskell-notebook:test1 \
     jupyter lab \
     --NotebookApp.token=''\
     --ServerApp.token='' \
     --ServerApp.port=8888 \
     --NotebookApp.port=8888 \
     --ServerApp.root_dir='/home/jovyan/work' \
     --NotebookApp.notebook_dir='/home/jovyan/work'
   