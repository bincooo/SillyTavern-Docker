#!/bin/sh

BASE=/home/node/app
USERNAME=$(printenv username)
PASSWORD=$(printenv password)

function env() {
  if [[ ! -z "${fetch}" ]]; then
    echo '远程获取参数...'
    curl -s "$fetch" -o data.json
    export reverse_proxy=$(jq -r .reverse_proxy data.json)
    export proxy_password=$(jq -r .proxy_password data.json)
    export api_key_makersuite=$(jq -r .api_key_makersuite data.json)
    export github_secret=$(jq -r .github_secret data.json)
    export github_project=$(jq -r .github_project data.json)
  fi

  echo
  echo "fetch = ${fetch}"
  echo "reverse_proxy = $reverse_proxy"
  echo "proxy_password = $proxy_password"
  echo "api_key_makersuite = $api_key_makersuite"
  echo "github_secret = $github_secret"
  echo "github_project = $github_project"
  echo "USERNAME = ${USERNAME}"
  echo "PASSWORD = ${PASSWORD}"
  echo
  echo

  IFS="," RESOURCES="糖水galV1.9.0g,糖水otomeV1.9.0g,修改版 V1.4.8_KaruKaru,修改版 V1.4.9_KaruKaru" && \
  \
  echo "*** Edit default $RESOURCES in OpenAI Settings ***" && \
  for R in $RESOURCES; do sed -i "s#\"reverse_proxy\": \"\",#\"reverse_proxy\": \"${reverse_proxy}\",#g" "data/default-user/OpenAI Settings/$R.json"; done || true && \
  for R in $RESOURCES; do sed -i "s#\"proxy_password\": \"\",#\"proxy_password\": \"${proxy_password}\",#g" "data/default-user/OpenAI Settings/$R.json"; done || true
  sed -i "s/\"api_key_makersuite\": \"\"/\"api_key_makersuite\": \"${api_key_makersuite}\"/g" secrets.json
  sed -i "s/\[github_secret\]/${github_secret}/g" launch.sh
  sed -i "s#\[github_project\]#${github_project}#g" launch.sh

  sed -i "s#\[proxies_url\]#${reverse_proxy}#g" config/settings.json
  sed -i "s/\[proxies_passwd\]/${proxy_password}/g" config/settings.json
}

function init() {
  mkdir ${BASE}/history
  cd ${BASE}/history

  git config --global user.email "huggingface@hf.com"
  git config --global user.name "complete-Mmx"
  git config --global init.defaultBranch main
  git init
  git remote add origin https://[github_secret]@github.com/[github_project].git
  git add .
  echo "'update history$(date "+%Y-%m-%d %H:%M:%S")'"
  git commit -m "'update history$(date "+%Y-%m-%d %H:%M:%S")'"
  git pull origin main

  cd ${BASE}

  DIR="${BASE}/history"
  if [ "$(ls -A $DIR | grep -v .git)" ]; then
    echo "Has history..."
  else
    echo "Empty history..."
    cp -r data/* history/
    cp -r secrets.json history/secrets.json
  fi

  rm -rf data
  ln -s history data

  cp -r config/settings.json history/default-user/settings.json
  ln -s history/default-user/settings.json data/default-user/settings.json

  rm -r secrets.json
  ln -s history/default-user/secrets.json secrets.json

  rm -r config.yaml
  cp config/config.yaml history/config.yaml
  ln -s history/config.yaml config.yaml
  sed -i "s/username: .*/username: \"${USERNAME}\"/" ${BASE}/config.yaml
  sed -i "s/password: .*/password: \"${PASSWORD}\"/" ${BASE}/config.yaml
  cat config.yaml
  echo "Init history."
  chmod -R 777 history

  nohup ./git-batch --commit 10s --name git-batch --email git-batch@github.com --push 1m -p history > access.log 2>1 &
}

function release() {
  rm -rf history
}

function update() {
  cd ${BASE}/history
  git pull origin main
  git add .
  echo "'update history$(date "+%Y-%m-%d %H:%M:%S")'"
  git commit -m "'update history$(date "+%Y-%m-%d %H:%M:%S")'"
  git push origin main
}

case $1 in
  env)
    env
  ;;
  init)
    init
  ;;
  release)
    release
  ;;
  update)
    update
  ;;
esac
