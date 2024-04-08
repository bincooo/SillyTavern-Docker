#!/bin/sh

BASE=/home/node/app

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
  echo
  echo

  IFS="," RESOURCES="新版主动,ny预设1.6.0,对话破限,小说文笔,新版主动,过激行为,鱼骨破限v3" && \
  \
  echo "*** Edit default $RESOURCES in OpenAI Settings ***" && \
  for R in $RESOURCES; do sed -i "s#\"reverse_proxy\": \"\",#\"reverse_proxy\": \"${reverse_proxy}\",#g" "config/OpenAI Settings/$R.json"; done || true && \
  for R in $RESOURCES; do sed -i "s#\"proxy_password\": \"\",#\"proxy_password\": \"${proxy_password}\",#g" "config/OpenAI Settings/$R.json"; done || true
  sed -i "s/\"api_key_makersuite\": \"\"/\"api_key_makersuite\": \"${api_key_makersuite}\"/g" secrets.json
  sed -i "s/\[github_secret\]/${github_secret}/g" auto.sh
  sed -i "s#\[github_project\]#${github_project}#g" auto.sh
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

  # 在移动原配置文件到历史目录 *之前* 更新 config.yaml 文件
  sed -i "s/username: .*/username: ${USERNAME}/" ${BASE}/config/config.yaml
  sed -i "s/password: .*/password: ${PASSWORD}/" ${BASE}/config/config.yaml

  DIR="${BASE}/history"
  if [ "$(ls -A $DIR | grep -v .git)" ]; then
    echo "Has history..."
  else
    echo "Empty history..."
    cp -r config/* history/
    cp -r secrets.json history/secrets.json
  fi

  rm -rf config
  ln -s history config
  rm -r secrets.json
  ln -s history/secrets.json secrets.json
  echo "Init history."
  chmod -R 777 history

  echo "'init history$(date "+%Y-%m-%d %H:%M:%S")'" > history/hello.txt
  nohup ./git-batch -v 4 --commit-interval 10s --name git-batch --email git-batch@github.com --push-interval 1m -p history > access.log 2>1 &
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
