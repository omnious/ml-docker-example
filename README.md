# ml-docker-example

This repository is for the simple example with docker environment.
It contains how to build sample image and how to access docker container in various research environment form(jupyter notebook, jupyter lab, ssh).

### How to build sample image.

1. Download docker in https://www.docker.com/

2. Pull base image 

```docker
docker pull nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04
```

3. Build sample image with Makefile. It actually build two images(Dockerfile, Dockerfile.opencv)

```bash
make all
```

4. Execute image with container
 
```bash
make dry-run
```

### Access to docker container with different port number.
with `make dry-run` command, port forwarding can be set in container and each external port number can be assigned to each research environment in Dockerfile.
1. jupyter notebook
```bash
host_server_ip_address:21501
```
2. jupyter lab
```bash
host_server_ip_address:21502
```
3. ssh
```bash
ssh -i private_key_location -p 25000 omnious@host_server_ip_address
```
