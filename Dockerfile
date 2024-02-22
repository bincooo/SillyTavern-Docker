FROM node:19.1.0-alpine3.16

# Arguments
ARG APP_HOME=/home/node/app

# Install system dependencies
RUN apk add gcompat tini git

# Ensure proper handling of kernel signals
ENTRYPOINT [ "tini", "--" ]

# Create app directory
WORKDIR ${APP_HOME}

# Env
# 代理转发地址
ENV reverse_proxy "https://www.xxx.com/v1"
# 代理转发token
ENV proxy_password "auto"
# gemini token （超级记忆）
ENV api_key_makersuite "xxx"
# github 项目访问凭证token
ENV github_secret ""
# github 项目名称
ENV github_project ""

# Install app dependencies
# COPY package*.json post-install.js ./
# --branch 1.11.4 指定酒馆版本，删除则获取最新代码
RUN git clone https://github.com/SillyTavern/SillyTavern.git --branch 1.11.4 .
RUN \
  echo "*** Install npm packages ***" && \
  npm install && npm cache clean --force

# Bundle app source
# COPY . ./

ADD auto.sh auto.sh
ADD git-batch git-batch
RUN chmod +x auto.sh && chmod +x git-batch


# Copy default chats, characters and user avatars to <folder>.default folder
RUN \
  IFS="," RESOURCES="assets,backgrounds,user,context,instruct,QuickReplies,movingUI,themes,characters,chats,groups,group chats,User Avatars,worlds,OpenAI Settings,NovelAI Settings,KoboldAI Settings,TextGen Settings" && \
  \
  echo "*** Store default $RESOURCES in <folder>.default ***" && \
  for R in $RESOURCES; do mv "public/$R" "public/$R.default"; done || true && \
  \
  echo "*** Create symbolic links to config directory ***" && \
  for R in $RESOURCES; do ln -s "../config/$R" "public/$R"; done || true && \
  \
  rm -f "config.yaml" "public/settings.json" || true && \
  ln -s "./config/config.yaml" "config.yaml" || true && \
  ln -s "../config/settings.json" "public/settings.json" || true && \
  mkdir "config" || true && \
  mkdir -p "public/user" || true


ADD ["user-default.png", "config/User Avatars/user-default.png"]
ADD ["OpenAI Settings", "config/OpenAI Settings"]
ADD ["QuickReplies", "config/QuickReplies"]
ADD secrets.json secrets.json
# 导入启动设置
ADD config.yaml config/config.yaml
# 导入服务设置
ADD settings.json config/settings.json
# 导入默认角色卡
ADD characters config/characters

# 配置初始化
RUN \
  IFS="," RESOURCES="新版主动,ny预设1.6.0,对话破限,小说文笔,新版主动,过激行为,鱼骨破限v3" && \
  \
  echo "*** Edit default $RESOURCES in OpenAI Settings ***" && \
  for R in $RESOURCES; do sed -i "s#\"reverse_proxy\": \"\",#\"reverse_proxy\": \"${reverse_proxy}\",#g" "config/OpenAI Settings/$R.json"; done || true && \
  for R in $RESOURCES; do sed -i "s#\"proxy_password\": \"\",#\"proxy_password\": \"${proxy_password}\",#g" "config/OpenAI Settings/$R.json"; done || true
RUN sed -i "s/\"api_key_makersuite\": \"\"/\"api_key_makersuite\": \"${api_key_makersuite}\"/g" secrets.json
RUN sed -i "s/\[github_secret\]/${github_secret}/g" auto.sh
RUN sed -i "s#\[github_project\]#${github_project}#g" auto.sh
RUN chmod -R 777 ${APP_HOME} && \
  ls -al ./config && \
  cat auto.sh


# Cleanup unnecessary files
RUN \
  echo "*** Cleanup ***" && \
  mv "./docker/docker-entrypoint.sh" "./" && \
  rm -rf "./docker" && \
  echo "*** Make docker-entrypoint.sh executable ***" && \
  chmod +x "./docker-entrypoint.sh" && \
  echo "*** Convert line endings to Unix format ***" && \
  dos2unix "./docker-entrypoint.sh"
RUN sed -i 's/# Start the server/.\/auto.sh init/g' docker-entrypoint.sh
RUN cat docker-entrypoint.sh

EXPOSE 8000

CMD [ "./docker-entrypoint.sh" ]