# Makefile

.PHONY: run stop rebuild restart ginko

GINKO_SYNC := ./scripts/sync_ginko_rfun.sh

ginko:
	$(GINKO_SYNC)

run: ginko
	docker compose up

stop:
	docker compose down

rebuild: ginko
	docker compose build --no-cache

restart:
	docker compose restart
