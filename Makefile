#!make

-include .env
ifneq (,$(wildcard .env))
export $(shell sed 's/=.*//' .env)
endif

setup: php-setup

clean:
	docker compose down
	docker compose rm -f -v
	docker builder prune

lint: php-lint yarn-lint

lint-fix: php-lint-fix yarn-lint-fix

test: php-test yarn-test php-infection cypress-run

migrate: php-migrate

## Frontend:
yarn:
	docker compose restart node

yarn-install:
	docker compose exec node yarn install

yarn-lint:
	docker compose exec node yarn run lint

yarn-lint-fix:
	docker compose exec node yarn run lint:fix

yarn-tsc:
	docker compose exec node yarn run vue-tsc --noEmit

yarn-watch:
	docker compose logs -f --tail=5 node

yarn-test:
	docker compose exec node yarn run test

yarn-production:
	docker compose exec node yarn run production

## Backend:
php-setup:
	test -e .env || cp .env.example .env
	docker compose build php-fpm # First build PHP-FPM as it creates a image used by other images
	docker compose up -d --force-recreate --always-recreate-deps
	make php-v
	make php-install


php-setup-full:
	test -e .env || cp .env.example .env
	docker compose build php-fpm --no-cache # First build PHP-FPM as it creates a image used by other images
	docker compose up -d --build --force-recreate --always-recreate-deps
	make php-install
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off php artisan key:generate'
	make php-migrate-fresh

php-install:
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off composer install'

php-lint:
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off ./vendor/bin/phpcstd'
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off ./vendor/bin/deptrac analyze depfile_support.yaml'

php-lint-fix:
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off ./vendor/bin/phpcstd --fix --continue'

php-test:
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off ./vendor/bin/phpunit'

php-infection:
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=coverage ./vendor/bin/infection'

php-test-watch:
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off ./vendor/bin/phpunit-watcher watch'

php-migrate: php-install
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off php artisan migrate'

php-make-migration: php-install
    docker compose exec php-fpm bash -c 'XDEBUG_MODE=off php artisan make:migration '

php-migrate-fresh: php-install
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off php artisan migrate:fresh --seed'

php-route-list:
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off php artisan route:list --except-path=telescope,vapor'

php-dependency-graph:
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off php vendor/bin/deptrac analyze --formatter=graphviz --graphviz-dump-image=dependencies.png'

php-cache-clear:
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off php artisan cache:clear'

php-artisan:
	docker compose exec php-fpm bash -c "XDEBUG_MODE=off php artisan $(filter-out $@,$(MAKECMDGOALS))"

dispatch-job:
	docker compose exec php-fpm bash -c "XDEBUG_MODE=off php artisan job:dispatch $(filter-out $@,$(MAKECMDGOALS))"

php-rollback-one:
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off php artisan migrate:rollback --step=1'

phpcstd:
	docker compose exec php-fpm bash -c 'XDEBUG_MODE=off ./vendor/bin/phpcstd --ci'

laravel:
	test -e .env || cp .env.example .env
	docker compose build php-fpm # First build PHP-FPM as it creates a image used by other images
	docker compose up -d --force-recreate --always-recreate-deps

	docker compose exec php-fpm bash -c "/usr/config/composer/vendor/bin/laravel $(filter-out $@,$(MAKECMDGOALS))"

composer:
	docker compose exec php-fpm bash -c "XDEBUG_MODE=off composer $(filter-out $@,$(MAKECMDGOALS))"

php-v:
	docker compose exec php-fpm bash -c "XDEBUG_MODE=off php -v"

docker-up:
	docker compose up -d

docker-restart: docker-stop docker-up

docker-stop:
	docker compose stop

cypress-run: docker-up cypress-install yarn-production cypress-run-fast

cypress-run-fast:
	npx cypress run

cypress-open: docker-up cypress-install yarn-production cypress-open-fast

cypress-open-fast:
	npx cypress open --e2e

cypress-delete-db-dump:
	docker compose exec php-fpm php artisan snapshot:delete cypress-dump

cypress-install:
	yarn cypress install
	docker compose exec -T mysql mysql -u"root" -p"${DB_PASSWORD}" -e "drop database if exists cypress"
	docker compose exec -T mysql mysql -u"root" -p"${DB_PASSWORD}" -e "create database cypress"
	docker compose exec -T mysql mysql -u"root" -p"${DB_PASSWORD}" -e "GRANT ALL PRIVILEGES ON cypress.* TO '${DB_USERNAME}'@'%';"

db-dump:
	docker compose exec -T mysql mysqldump -u"root" -p"${DB_PASSWORD}" ${DB_DATABASE} > backup.sql
db-load-from-dump:
	docker compose exec -T mysql mysql -u"root" -p"${DB_PASSWORD}" ${DB_DATABASE} < backup.sql


db-dump2:
	docker compose exec -T sql mariadb-dump -u"root" -p"${DB_PASSWORD}" ${DB_DATABASE} > backup_sql.sql
db-load-from-dump2:
	docker compose exec -T sql mysql -u"root" -p"${DB_PASSWORD}" ${DB_DATABASE} < backup_sql.sql

load-db-in2-sql:
	docker compose exec -T sql mysql -u"root" -p"${DB_PASSWORD}" ${DB_DATABASE} < backup.sql
