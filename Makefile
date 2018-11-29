## Parameters used in docker-compose file
include .env

## Custom commands (this section should not be modified)
DOCKER           = docker exec -u $(ANSIBLE_USER) -w $(PLAYBOOK_HOME) -e "ANSIBLE_HOST_KEY_CHECKING=False" -t $(COMPOSE_PROJECT_NAME)_ansible_1
PING             = $(DOCKER) ansible -m ping
PLAYBOOK         = $(DOCKER) ansible-playbook
PLAY             = $(PLAYBOOK) $(ANSIBLE_PLAY_PLAYBOOK) $(ANSIBLE_PLAY_EXTRAVARS)
SKIP             = --skip-tags $(SKIP_TAGS)
ANSIBLE_SSH_USER = -e "ansible_ssh_user=$(ANSIBLE_USER)"
ANSIBLE_VAULT    = --vault-password-file=/run/secrets/vault

## Common docker parameters
COMPOSE_PROJECT_NAME = testing

## Regular playbooks run parameters
ANSIBLE_PLAY_EXTRAVARS = $(ANSIBLE_SSH_USER) $(ANSIBLE_VAULT) -e "@/extra_vars/play.yml"
ANSIBLE_PLAY_PLAYBOOK  = main.yml
SKIP_TAGS              = skip
DBG_OPTIONS            = $(WIP_OPTIONS) -e "@/extra_vars/debug.yml" -vvv
WIP_OPTIONS            = $(SKIP) -t wip -D

## Custom initialization playbook parameters
ANSIBLE_INIT_EXTRAVARS = $(ANSIBLE_PLAY_EXTRAVARS)
ANSIBLE_INIT_PLAYBOOK  = prerequisite.yml
ANSIBLE_INIT_TAGS      = $(SKIP) -t init

export COMPOSE_PROJECT_NAME

all: wip

base:
	@echo "============================================="
	@echo "Building images from DockerFiles"
	@echo "---------------------------------------------"
	docker build \
		-t ansible/centos:base \
		-f ansible/centos-runner/base.dockerfile .
	docker build \
		-t ansible/centos:remote-runner \
		-f ansible/centos-runner/remote-runner.dockerfile .
	docker build \
		-t ansible/centos:remote-target \
		-f ansible/centos-runner/remote-target.dockerfile .
ifdef ANSIBLE_VERSION
	docker build \
		--build-arg ANSIBLE_VERSION=$(ANSIBLE_VERSION) \
		-t ansible/centos:remote-${ANSIBLE_VERSION}-runner \
		-f ansible/centos-runner/custom-runner.dockerfile .
endif
	@echo ""

build: clean base
	@echo "============================================="
	@echo "Building images from Compose"
	@echo "---------------------------------------------"
	docker-compose build
	@echo ""

clean: down
	@echo "============================================="
	@echo "Cleaning orphaned objects"
	@echo "---------------------------------------------"
	docker system prune -f
	@echo ""

clean-debug: init debug

clean-full: init full

clean-play: init play

clean-test: build up test

clean-wip: init wip

check: clean-test down

debug:
	@echo "============================================="
	@echo "Debug tasks with 'wip' tags"
	@echo "---------------------------------------------"
	$(PLAY) $(DBG_OPTIONS)
	@echo ""

down:
	@echo "============================================="
	@echo "Stopping containers"
	@echo "---------------------------------------------"
	docker-compose down --remove-orphans -v
	@echo ""

full: up
	@echo "============================================="
	@echo "Playing full playbook (including $(SKIP_TAGS) tags)"
	@echo "---------------------------------------------"
	$(PLAY)
	@echo ""

init: build up
	@echo "============================================="
	@echo "Playing initialization $(ANSIBLE_INIT_PLAYBOOK) playbook"
	@echo "---------------------------------------------"
	$(PLAYBOOK) $(ANSIBLE_INIT_PLAYBOOK) $(ANSIBLE_INIT_EXTRAVARS)
	@echo ""

	@echo "============================================="
	@echo "Playing initialization tags ($(ANSIBLE_INIT_TAGS))"
	@echo "---------------------------------------------"
	$(PLAY) $(ANSIBLE_INIT_TAGS)
	@echo ""

play: up
	@echo "============================================="
	@echo "Playing full playbook (without $(SKIP_TAGS) tags)"
	@echo "---------------------------------------------"
	$(PLAY) $(SKIP)
	@echo ""

test: up
	@echo "============================================="
	@echo "Testing Ansible controller local connectivity"
	@echo "---------------------------------------------"
	$(PING) local
	@echo ""

	@echo "============================================="
	@echo "Testing connectivity to managed containers"
	@echo "---------------------------------------------"
	$(PING) $(ANSIBLE_SSH_USER) all:!unmanaged
	@echo ""

up:
	@echo "============================================="
	@echo "Starting containers"
	@echo "---------------------------------------------"
	docker-compose up -d
	@echo ""

wip: up
	@echo "============================================="
	@echo "Playing tasks with 'wip' tags only"
	@echo "---------------------------------------------"
	$(PLAY) $(WIP_OPTIONS)
	@echo ""
