base_port=25000

all: generate-key opencv main

generate-key:
	mkdir -p ./ssh-key
	ssh-keygen -C "docker-env" -f ./ssh-key/docker-env  -q -N ""

opencv: 
	docker build -f Dockerfile.opencv -t res-env/opencv .
main: 
	docker build -f Dockerfile -t res-env/sample .

dry-run:
	docker run -it --rm \
	-p $(base_port):22 \
	-p $(shell expr $(base_port) + 1 ):8800 \
	-p $(shell expr $(base_port) + 2 ):8801 \
	-p $(shell expr $(base_port) + 3 ):6003 \
	-p $(shell expr $(base_port) + 4 ):6004 \
	-p $(shell expr $(base_port) + 5 ):6005 \
	-p $(shell expr $(base_port) + 6 ):6006 \
	-p $(shell expr $(base_port) + 7 ):6007 \
	-p $(shell expr $(base_port) + 8 ):6008 \
	-p $(shell expr $(base_port) + 9 ):6009 \
	-p $(shell expr $(base_port) + 10 ):6010 \
	-v $(shell pwd)/workspace:/home/omnious/workspace \
	res-env/sample
