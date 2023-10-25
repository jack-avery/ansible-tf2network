.PHONY: all base admins sm srcds deploy

all: sm srcds deploy

PROD_OPTS := --limit prod

base:
	@ansible-playbook playbooks/base-tf2server.yml

admins:
	@ansible-playbook $(PROD_OPTS) playbooks/admins.yml

sm:
	@ansible-playbook $(PROD_OPTS) playbooks/sourcemod.yml

srcds:
	@ansible-playbook $(PROD_OPTS) playbooks/srcds.yml

deploy:
	@ansible-playbook $(PROD_OPTS) playbooks/deploy.yml
