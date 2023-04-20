SHELL := /bin/bash

.PHONY:
init:
	@terraform -chdir=./provision init

.PHONY:
plan:
	@terraform -chdir=./provision plan

.PHONY:
create:
	@terraform -chdir=./provision apply

.PHONY:
destroy:
	@terraform -chdir=./provision destroy
