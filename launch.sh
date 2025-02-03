#!/bin/sh

BASE=/home/node/app
USERNAME=$(printenv username)
PASSWORD=$(printenv password)

function env() {
  if [[ ! -z "${fetch}" ]]; then
    echo '远程获取参数...'
    curl -s "$fetch" -o data.json
    export github_secret=$(jq -r .github_secret data.json)
    export github_project=$(jq -r .github_project data.json)
  fi

  if [[ -z "${USERNAME}" ]]; then
    USERNAME="root"
  fi

  if [[ -z "${PASSWORD}" ]]; then
    PASSWORD="123456"
  fi

  echo
  echo "fetch = ${fetch}"
  echo "github_secret = $github_secret"
  echo "github_project = $github_project"
  echo "USERNAME = ${USERNAME}"
  echo "PASSWORD = ${PASSWORD}"
  echo
  echo

  sed -i "s/\[github_secret\]/${github_secret}/g" launch.sh
  sed -i "s#\[github_project\]#${github_project}#g" launch.sh
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

  rm -r config.yaml
  cp config/config.yaml history/config.yaml
  ln -s history/config.yaml config.yaml
  sed -i "s/username: .*/username: \"${USERNAME}\"/" ${BASE}/config.yaml
  sed -i "s/password: .*/password: \"${PASSWORD}\"/" ${BASE}/config.yaml
  sed -i "s/whitelistMode: true/whitelistMode: false/" ${BASE}/config.yaml
  sed -i "s/basicAuthMode: false/basicAuthMode: true/" ${BASE}/config.yaml
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
