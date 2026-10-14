.PHONY: help venv build planner positions robot sim shell validate generate dry-run docker-validate run clean

help:
	@grep -E '^[a-z-]+:.*?##' $(MAKEFILE_LIST) | sed 's/:.*##/\t/'

venv:      
	./scripts/setup_venv.sh

build:     
	./scripts/build.sh

positions: 
	./scripts/fetch_positions.sh

robot:     
	./scripts/start_robot.sh

sim:       
	docker compose up -d sim
	docker compose logs -f sim


shell:      
	docker compose run --rm --no-deps nao bash

planner:    
	docker compose run --rm planner bash

PLAN ?= choreography/out/plan.json
PY3  ?= python3

validate:   
	PYTHONPATH=src $(PY3) -m planner.plan --validate $(PLAN)

generate:   
	PYTHONPATH=src $(PY3) -m planner.plan -o choreography/out/plan.json

dry-run:   
	docker compose run --rm --no-deps nao python src/executor/run_choreography.py $(PLAN) --dry-run

docker-validate: 
	docker compose run --rm planner python -m planner.plan --validate $(PLAN)

run:    
	docker compose run --rm --no-deps nao python src/executor/run_choreography.py $(PLAN)


clean:     
	docker compose down --remove-orphans
	-docker image rm nao-challenge/naoqi:local nao-challenge/planner:local
