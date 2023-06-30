.PHONY: all base admins sm srcds

all: sm srcds

base:
	@ansible-playbook playbooks/base-tf2server.yml

admins:
	@ansible-playbook playbooks/admins.yml

sm:
	@ansible-playbook playbooks/sourcemod.yml

srcds:
	@ansible-playbook playbooks/srcds.yml
