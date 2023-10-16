.PHONY: all base admins sm srcds

all: sm srcds cron

base:
	@ansible-playbook playbooks/base-tf2server.yml

admins:
	@ansible-playbook playbooks/admins.yml

sm:
	@ansible-playbook playbooks/sourcemod.yml

cron:
	@ansible-playbook playbooks/cron.yml

srcds:
	@ansible-playbook playbooks/srcds.yml
