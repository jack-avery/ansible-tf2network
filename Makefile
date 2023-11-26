.PHONY: all base admins sm srcds deploy

all: sm srcds relay deploy

base:
	@ansible-playbook playbooks/base-tf2server.yml

sm:
	@ansible-playbook --limit prod playbooks/sourcemod.yml

admins:
	@ansible-playbook --limit prod playbooks/admins.yml --extra-vars "only=$(ONLY)"

srcds:
	@ansible-playbook --limit prod playbooks/srcds.yml --extra-vars "only=$(ONLY)"

relay:
	@ansible-playbook --limit prod playbooks/relay.yml --extra-vars "only=$(ONLY)"

deploy:
	@ansible-playbook --limit prod playbooks/deploy.yml --extra-vars "only=$(ONLY)"

update:
	@ansible-playbook --limit prod playbooks/update.yml --extra-vars "only=$(ONLY)"
