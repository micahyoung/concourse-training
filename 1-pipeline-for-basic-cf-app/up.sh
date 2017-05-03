#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if ! [ -d state/ ]; then
  exit "No State, exiting"
  exit 1
fi

source state/env.sh
CONCOURSE_TARGET=${CONCOURSE_TARGET:?"env!"}
CONCOURSE_APP_PIPELINE=${CONCOURSE_APP_PIPELINE:?"env!"}
STATE_REPO_URL=${STATE_REPO_URL:?"env!"}
STATE_REPO_PRIVATE_KEY=${STATE_REPO_PRIVATE_KEY:?"env!"}
APP_REPO_URL=${APP_REPO_URL:?"env!"}
CF_API_URL=${CF_API_URL:?"env!"}
CF_USERNAME=${CF_USERNAME:?"env!"}
CF_PASSWORD=${CF_PASSWORD:?"env!"}
CF_ORG=${CF_ORG:?"env!"}
CF_SPACE=${CF_SPACE:?"env!"}

mkdir -p bin
PATH=$(pwd)/bin:$PATH

if ! [ -f bin/fly ]; then
  curl -L "http://$CONCOURSE_DOMAIN/api/v1/cli?arch=amd64&platform=darwin" > bin/fly
  chmod +x bin/fly
fi

if ! fly targets | grep $CONCOURSE_TARGET; then
  fly login \
    --target $CONCOURSE_TARGET \
    --concourse-url "http://$CONCOURSE_DOMAIN" \
    --username $CONCOURSE_USERNAME \
    --password $CONCOURSE_PASSWORD \
  ;
fi

if ! fly pipelines -t $CONCOURSE_TARGET | grep $CONCOURSE_PIPELINE; then
  fly set-pipeline \
    --target $CONCOURSE_TARGET \
    --pipeline $CONCOURSE_APP_PIPELINE \
    --config cf-app-pipeline.yml \
    --var cf_api_url="$CF_API_URL" \
    --var cf_username="$CF_USERNAME" \
    --var cf_password="$CF_PASSWORD" \
    --var cf_org="$CF_ORG" \
    --var cf_space="$CF_SPACE" \
    --var app_repo_url="$APP_REPO_URL" \
    --var state_repo_url="$STATE_REPO_URL" \
    --var state_repo_private_key="$STATE_REPO_PRIVATE_KEY" \
    --non-interactive \
  ;
fi