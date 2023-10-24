.PHONY: all base admins sm srcds

all: sm srcds deploy cron

base:
	@ansible-playbook playbooks/base-tf2server.yml

admins:
	@ansible-playbook playbooks/admins.yml

sm:
	@ansible-playbook playbooks/sourcemod.yml

srcds:
	@ansible-playbook playbooks/srcds.yml

deploy:
	@ansible-playbook playbooks/deploy.yml

cron:
	@ansible-playbook playbooks/cron.yml

