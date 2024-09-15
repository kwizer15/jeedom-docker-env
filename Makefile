docker:=$(shell which docker)
git:=$(shell which git)
CORE_PATH=jeedom/$(JEEDOM_CORE_PATH)

include .env

.env: .env.dist
	cp .env.dist .env

$(CORE_PATH):
	$(git) submodule add -b $(JEEDOM_CORE_BRANCH) --force $(JEEDOM_CORE_REPOSITORY) $(CORE_PATH)
	$(git) submodule update --init --recursive
	$(git) reset .gitmodules
	$(git) reset $(CORE_PATH)
	rm $@/composer.lock

$(CORE_PATH)/core/config/common.config.php: $(CORE_PATH)
	cp config/common.config.php $@

$(CORE_PATH)/composer.lock: $(CORE_PATH)/composer.json
	$(docker) compose exec php sh -c "composer install --no-ansi --no-interaction --no-plugins --no-progress --no-scripts --optimize-autoloader"

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
	$(MAKE) $(CORE_PATH)/composer.lock
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

test: $(CORE_PATH)/vendor/phpunit
	$(docker) compose run php vendor/bin/phpunit
.PHONY: test
