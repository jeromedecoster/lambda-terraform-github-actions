#!/bin/bash

#
# variables
#

# AWS variables
AWS_PROFILE=default
AWS_REGION=eu-west-3
# project name
PROJECT_NAME=lambda-terraform-github-actions


# the directory containing the script file
dir="$(cd "$(dirname "$0")"; pwd)"
cd "$dir"

log()   { echo -e "\e[30;47m ${1^^} \e[0m ${@:2}"; }        # $1 uppercase background white
info()  { echo -e "\e[48;5;28m ${1^^} \e[0m ${@:2}"; }      # $1 uppercase background green
warn()  { echo -e "\e[48;5;202m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background orange
error() { echo -e "\e[48;5;196m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background red

# log $1 in underline then $@ then a newline
under() {
    local arg=$1
    shift
    echo -e "\033[0;4m${arg}\033[0m ${@}"
    echo
}

usage() {
    under usage 'call the Makefile directly: make dev
      or invoke this file directly: ./make.sh dev'
}

create-env() {
    # check if user already exists (return something if user exists, otherwise return nothing)
    local exists=$(aws iam list-user-policies \
        --user-name $PROJECT_NAME \
        --profile $AWS_PROFILE \
        2>/dev/null)
        
    [[ -n "$exists" ]] && { error abort user $PROJECT_NAME already exists; return; }

    # create a user named $PROJECT_NAME
    log create iam user $PROJECT_NAME
    aws iam create-user \
        --user-name $PROJECT_NAME \
        --profile $AWS_PROFILE \
        1>/dev/null

    aws iam attach-user-policy \
        --user-name $PROJECT_NAME \
        --policy-arn arn:aws:iam::aws:policy/PowerUserAccess \
        --profile $AWS_PROFILE

    local key=$(aws iam create-access-key \
        --user-name $PROJECT_NAME \
        --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \
        --profile $AWS_PROFILE \
        2>/dev/null)

    local AWS_ACCESS_KEY_ID=$(echo "$key" | jq '.AccessKeyId' --raw-output)
    log AWS_ACCESS_KEY_ID $AWS_ACCESS_KEY_ID
    
    local AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq '.SecretAccessKey' --raw-output)
    log AWS_SECRET_ACCESS_KEY $AWS_SECRET_ACCESS_KEY

    # envsubst tips : https://unix.stackexchange.com/a/294400
    # create .env file
    cd "$dir"
    # export variables for envsubst
    export AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY
    envsubst < .env.tmpl > .env

    info created file .env
}

# create env + terraform init
setup() {
    create-env
    # terraform init
    tf-init
}

# delete env + terraform destroy
delete() {
    # delete a user named $PROJECT_NAME
    log delete iam user $PROJECT_NAME

    aws iam detach-user-policy \
        --user-name $PROJECT_NAME \
        --policy-arn arn:aws:iam::aws:policy/PowerUserAccess \
        --profile $AWS_PROFILE \
        2>/dev/null

    source "$dir/.env"
    aws iam delete-access-key \
        --user-name $PROJECT_NAME \
        --access-key-id $AWS_ACCESS_KEY_ID \
        2>/dev/null

    aws iam delete-user \
        --user-name $PROJECT_NAME \
        --profile $AWS_PROFILE

    cd "$dir"
    rm --force .env
    
    # terraform destroy
    tf-destroy
}

tf-init() {
    cd "$dir/infra"
    terraform init
}

tf-validate() {
    cd "$dir/infra"
    terraform fmt -recursive
	terraform validate
}

tf-apply() {
    cd "$dir/infra"
    terraform plan -out=terraform.plan
    terraform apply -auto-approve terraform.plan
}

tf-destroy() {
    cd "$dir/infra"
    terraform destroy \
        -auto-approve
}

# hello-dev
hello-dev() {
    cd "$dir/infra"
    curl $(terraform output -raw hello_dev)
}

# hello-prod
hello-prod() {
    cd "$dir/infra"
    curl $(terraform output -raw hello_prod)
}



# if `$1` is a function, execute it. Otherwise, print usage
# compgen -A 'function' list all declared functions
# https://stackoverflow.com/a/2627461
FUNC=$(compgen -A 'function' | grep $1)
[[ -n $FUNC ]] && { info execute $1; eval $1; } || usage;
exit 0