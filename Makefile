.PHONY: all base sm admins srcds relay deploy

all: base sm srcds deploy relay

base:
	@ansible-playbook --limit prod playbooks/base-tf2server.yml --extra-vars "clean=$(CLEAN)"

sm:
	@ansible-playbook --limit prod playbooks/sourcemod.yml

admins:
	@ansible-playbook --limit prod playbooks/admins.yml --extra-vars "only=$(ONLY)"

srcds:
	@ansible-playbook --limit prod playbooks/srcds.yml --extra-vars "only=$(ONLY)"

relay:
	python3 manifest.py
	@ansible-playbook playbooks/relay.yml --extra-vars "only=$(ONLY)"

deploy:
	@ansible-playbook --limit prod playbooks/deploy.yml --extra-vars "only=$(ONLY)"
