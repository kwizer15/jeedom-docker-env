docker:=$(shell which docker)
git:=$(shell which git)

core:
	$(git) submodule update --init

build:
	$(docker) compose build php
.PHONY: build

up: core
	$(docker) compose up --detach
.PHONY: up

logs:
	$(docker) compose logs --follow php
.PHONY: logs

bash:
	$(docker) compose exec php bash
.PHONY: bash

test:
	$(docker) compose run php vendor/bin/phpunit
