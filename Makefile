docker:=$(shell which docker)
git:=$(shell which git)
CORE_PATH=jeedom/$(JEEDOM_CORE_PATH)

qa := $(docker) run --rm -t -v `pwd`:/project --workdir="/project" jakzal/phpqa
phpcsfixer := $(qa) php-cs-fixer
PHP_CS_FIXER_CONFIGURATION_FILE ?= .php-cs-fixer.php7.php

include .env

.env: .env.dist
	cp .env.dist .env

$(CORE_PATH):
	$(git) submodule add -b $(JEEDOM_CORE_BRANCH) --force $(JEEDOM_CORE_REPOSITORY) $(CORE_PATH)
	$(git) submodule update --init --recursive
	$(git) reset .gitmodules
	$(git) reset $(CORE_PATH)

$(CORE_PATH)/core/config/common.config.php: $(CORE_PATH)
	cp config/common.config.php $@

install: $(CORE_PATH)/composer.lock
	$(docker) compose exec php sh -c "composer install --no-ansi --no-interaction --no-plugins --no-progress --no-scripts --optimize-autoloader"
.PHONY: install

$(CORE_PATH)/vendor/phpunit:
	$(docker) compose run php composer require --dev phpunit/phpunit

.db_initialized:
	$(docker) compose exec php php tests/bootstrap.php
	touch $@

compose.override.yaml: compose.override.yaml.dist
	cp $< $@

build:
	$(docker) compose build php
.PHONY: build

up: $(CORE_PATH)/core/config/common.config.php
	$(docker) compose up --detach --remove-orphans
	$(MAKE) install
	$(MAKE) .db_initialized
.PHONY: up

stop:
	$(docker) compose stop

logs:
	$(docker) compose logs --follow php
.PHONY: logs

bash/%:
	$(docker) compose exec $(@F) sh
.PHONY: bash

remove: own
	$(docker) compose down
	rm -rf $(CORE_PATH)
	rm -rf .db_initialized
.PHONY: remove

own:
	sudo chown $(shell id -u):$(shell id -g) -R $(CORE_PATH)
.PHONY: own

tests: $(CORE_PATH)/vendor/phpunit
	$(docker) compose run php php -dpcov.enabled=1 -dpcov.directory=. -dpcov.exclude="~vendor~" vendor/bin/phpunit tests/BC/pluginBCTest.php --coverage-html var/phpunit
.PHONY: test

phpcs: ## Lint - PHPCs - Checks coding standards
	$(phpcsfixer) fix --dry-run -v --config=$(PHP_CS_FIXER_CONFIGURATION_FILE)

fixcs: ## Lint - PHPCs - Fixes coding standards
	@$(phpcsfixer) fix --config=$(PHP_CS_FIXER_CONFIGURATION_FILE)

phpstan: $(CORE_PATH)/phpstan.phar
	$(docker) compose run --rm php php -dmemory_limit=-1 phpstan.phar analyze --configuration phpstan.neon
.PHONY: phpstan

phpstan-bl: $(CORE_PATH)/phpstan.phar
	$(docker) compose run --rm php php -dmemory_limit=-1 phpstan.phar analyze --configuration phpstan.neon --generate-baseline=tmp-baseline.neon
.PHONY: phpstan-bl

$(CORE_PATH)/phpstan.phar:
	cd $(CORE_PATH) && wget https://github.com/phpstan/phpstan/releases/latest/download/phpstan.phar

