.PHONY: all base sm admins srcds relay deploy

all: sm srcds deploy relay-deploy

base:
	@ansible-playbook --limit prod playbooks/base-tf2server.yml

sm:
	@ansible-playbook --limit prod playbooks/sourcemod.yml

sbpp-install:
	@ansible-playbook --limit metrics playbooks/sbpp-install.yml

sbpp:
	@ansible-playbook --limit metrics playbooks/sbpp.yml

ssh-gen:
	@ansible-playbook --limit prod playbooks/ssh-gen.yml

ssh-auth:
	@ansible-playbook --limit metrics playbooks/ssh-auth.yml

cycle: ssh-gen ssh-auth sbpp

admins:
	@ansible-playbook --limit prod playbooks/admins.yml --extra-vars "only=$(ONLY)"

srcds:
	@ansible-playbook --limit prod playbooks/srcds.yml --extra-vars "only=$(ONLY)"

relay:
	@ansible-playbook playbooks/relay.yml

relay-deploy:
	python3 manifest.py
	@ansible-playbook playbooks/relay-deploy.yml

deploy:
	@ansible-playbook --limit prod playbooks/deploy.yml --extra-vars "only=$(ONLY)"
