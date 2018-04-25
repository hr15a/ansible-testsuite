.PHONY: all clean-test check build run test base clean down

all: build

clean-test: run test

check: clean-test down

build: clean base
	docker-compose build

run: build
	docker-compose up -d

test:
	docker exec -it centos-runner ansible -i "localhost," -c local  all -m ping

base:
	docker build -t ansible/centos-runner:base -f ansible/centos-runner/base.dockerfile .

clean:
	docker-compose down --remove-orphans -v
	docker system prune -f

down:
	docker-compose down
