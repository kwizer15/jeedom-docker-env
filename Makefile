docker:=$(shell which docker)
git:=$(shell which git)

include .env

.env: .env.dist
	cp .env.dist .env

jeedom/$(JEEDOM_CORE_PATH):
	$(git) submodule add --force $(JEEDOM_CORE_REPOSITORY) jeedom/$(JEEDOM_CORE_PATH)
	$(git) submodule update --init --recursive
	$(git) reset .gitmodules
	$(git) reset jeedom/$(JEEDOM_CORE_PATH)

build:
	$(docker) compose build php
.PHONY: build

up: jeedom/$(JEEDOM_CORE_PATH)
	$(docker) compose up --detach
.PHONY: up

logs:
	$(docker) compose logs --follow php
.PHONY: logs

bash:
	$(docker) compose exec php bash
.PHONY: bash

remove:
	$(docker) compose down
	rm -rf jeedom/$(JEEDOM_CORE_PATH)
.PHONY: remove

own:
	sudo chown $(shell id -u):$(shell id -g) -R jeedom/$(JEEDOM_CORE_PATH)
.PHONY: own

test:
	$(docker) compose run php vendor/bin/phpunit
.PHONY: test
