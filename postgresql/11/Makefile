/*
 * @Author: cnak47
 * @Date: 2018-10-15 14:09:40
 * @LastEditors: cnak47
 * @LastEditTime: 2019-12-24 15:05:14
 * @Description: 
 */
IMAGE:=cnlubo/postgresql
all: build

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "   1. make build/release   - build image"
	@echo "   2. make view            - view  image"
	@echo "   3. make quickstart      - start PostgreSQL"
	@echo "   4. make Login           - login to PostgreSQL"
	@echo "   5. make stop            - stop  PostgreSQL"
	@echo "   6. make logs            - view logs"
	@echo "   7. make purge           - stop and remove the container"

build:
	@docker build --tag=$(IMAGE) -f Dockerfile.postgres .
release:
	@docker build --tag=$(IMAGE):$(shell cat VERSION) -f Dockerfile.postgres .
view:
	@docker run --rm -it  $(IMAGE):$(shell cat VERSION) bash

quickstart:
		@echo "Starting PostgreSQL..."
		@docker run --name=postgres-demo -d -p 54321:5432 \
			-v /var/run/docker.sock:/run/docker.sock \
			-v $(shell which docker):/bin/docker \
			-v /Users/ak47/Documents/pgdata:/var/lib/postgresql \
			-e PG_PASSWORD='12345678' \
			-e DB_EXTENSION=unaccent,pg_trgm \
			-e DB_USER=admin \
		    -e DB_PASS=admin123 \
			-e DB_NAME=test_db1,test_db2 \
			$(IMAGE):$(shell cat VERSION)>/dev/null
		@echo "Please be patient. This could take a while..."
		@echo "PostgreSQL will be connect at localhost 54321 Port"
		@echo "Type 'make logs' for the logs"
login:
	    @echo "Login to PostgreSQL..."
		# docker exec -it postgres-demo gosu postgres psql
		docker exec -it postgres-demo gosu postgres psql -U admin -d test_db1
stop:
		@echo "Stopping PostgreSQL..."
		@docker stop postgres-demo >/dev/null

purge: stop
		@echo "Removing stopped container..."
		@docker rm postgres-demo >/dev/null

logs:
		@docker logs -f postgres-demo
