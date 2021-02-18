.SILENT:

help:
	{ grep --extended-regexp '^[a-zA-Z_-]+:.*#[[:space:]].*$$' $(MAKEFILE_LIST) || true; } \
	| awk 'BEGIN { FS = ":.*#[[:space:]]*" } { printf "\033[1;32m%-25s\033[0m%s\n", $$1, $$2 }'

setup: # create env + terraform init
	./make.sh setup

delete: # delete env + terraform destroy
	./make.sh delete

tf-init: # terraform init
	./make.sh tf-init

tf-validate: # terraform validate
	./make.sh tf-validate

tf-apply: # terraform plan + apply
	./make.sh tf-apply

tf-destroy: # terraform destroy
	./make.sh tf-destroy

hello-dev: # curl dev/hello
	./make.sh hello-dev

hello-prod: # curl prod/hello
	./make.sh hello-prod