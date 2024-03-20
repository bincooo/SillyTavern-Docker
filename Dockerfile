FROM node:19.1.0-alpine3.16

# Arguments
ARG APP_HOME=/home/node/app

# Install system dependencies
RUN apk add gcompat tini git jq curl

# Ensure proper handling of kernel signals
ENTRYPOINT [ "tini", "--" ]

# Create app directory
WORKDIR ${APP_HOME}

# Env
# 是否远程获取下面的参数 是个链接，返回一个json；执行完后关闭这个链接即可保密
# 返回内容:
#  {
#    "reverse_proxy": "https://onekey.xxx.top/v1",
#    "proxy_password": "sk-ssvJn4VQAk596Lvv3548xxx",
#    "api_key_makersuite": "AIzaSyAm5S9kl22DDNSXmnd4vgxxx",
#    "github_secret": "github_pat_11AIWDQ2A0cLSEdwiwiZNC_10II4TsFExxx",
#    "github_project": "bincooo/history"
#  }
ENV fetch "https://www.xxxx.top/alist/p/sercets.json"
# 代理转发地址
ENV reverse_proxy ""
# 代理转发token
ENV proxy_password ""
# gemini token
ENV api_key_makersuite ""
# github 项目访问凭证token
ENV github_secret ""
# github 项目名称
ENV github_project ""

# Install app dependencies
# COPY package*.json post-install.js ./
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
  #\
  #for R in $RESOURCES; do mkdir "config/$R"; done || true

ADD ["user-default.png", "config/User Avatars/user-default.png"]
ADD ["OpenAI Settings", "config/OpenAI Settings"]
ADD ["QuickReplies", "config/QuickReplies"]
ADD themes config/themes
ADD secrets.json secrets.json
# 启动设置
ADD config.yaml config/config.yaml
# 服务设置
ADD settings.json config/settings.json
# 导入角色卡
ADD characters config/characters


# Cleanup unnecessary files
RUN \
  echo "*** Cleanup ***" && \
  mv "./docker/docker-entrypoint.sh" "./" && \
  rm -rf "./docker" && \
  echo "*** Make docker-entrypoint.sh executable ***" && \
  chmod +x "./docker-entrypoint.sh" && \
  echo "*** Convert line endings to Unix format ***" && \
  dos2unix "./docker-entrypoint.sh"
RUN sed -i 's/# Start the server/.\/auto.sh env \&\& .\/auto.sh init/g' docker-entrypoint.sh
RUN chmod -R 777 ${APP_HOME}

EXPOSE 8000

CMD [ "./docker-entrypoint.sh" ]