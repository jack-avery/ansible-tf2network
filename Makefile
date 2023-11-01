.PHONY: all base admins sm srcds deploy

all: sm srcds deploy

base:
	@ansible-playbook playbooks/base-tf2server.yml

sm:
	@ansible-playbook --limit prod playbooks/sourcemod.yml

admins:
	@ansible-playbook --limit prod playbooks/admins.yml --extra-vars "only=$(ONLY)"

srcds:
	@ansible-playbook --limit prod playbooks/srcds.yml --extra-vars "only=$(ONLY)"

deploy:
	@ansible-playbook --limit prod playbooks/deploy.yml --extra-vars "only=$(ONLY)"
