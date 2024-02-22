#!/bin/sh

function init() {
  mkdir /home/node/app/history
  cd /home/node/app/history

  git config --global user.email "huggingface@hf.com"
  git config --global user.name "complete-Mmx"
  git config --global init.defaultBranch main
  git init
  git remote add origin https://[github_secret]@github.com/[github_project].git
  git add .
  echo "'update history$(date "+%Y-%m-%d %H:%M:%S")'"
  git commit -m "'update history$(date "+%Y-%m-%d %H:%M:%S")'"
  git pull origin main

  cd /home/node/app
  DIR="/home/node/app/history"
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

  echo "'init history$(date "+%Y-%m-%d %H:%M:%S")'" >> history/hello.txt
  nohup ./git-batch -v 4 --commit-interval 10s --name git-batch --email git-batch@github.com --push-interval 1m -p history > access.log 2>1 &
}

function release() {
  rm -rf history
}

function update() {
  cd /home/node/app/history
  git pull origin main
  git add .
  echo "'update history$(date "+%Y-%m-%d %H:%M:%S")'"
  git commit -m "'update history$(date "+%Y-%m-%d %H:%M:%S")'"
  git push origin main
}

case $1 in
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
