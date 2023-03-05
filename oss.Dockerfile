FROM node:14-alpine as builder

ARG ACCESS_KEY_ID
ARG ACCESS_KEY_SECRET
ARG ENDPOINT
ENV PUBLIC_URL https://learn-deploy.oss-cn-beijing.aliyuncs.com/

WORKDIR /code

# 为了更好的缓存，把它放在前边
RUN wget http://gosspublic.alicdn.com/ossutil/1.7.7/ossutil64 -O /usr/local/bin/ossutil \
  && chmod 755 /usr/local/bin/ossutil \
  && ossutil config -i $ACCESS_KEY_ID -k $ACCESS_KEY_SECRET -e $ENDPOINT

# 单独分离 package.json，是为了安装依赖可最大限度利用缓存
RUN npm i pnpm -g
ADD package.json pnpm-lock.yaml /code/
RUN pnpm config set registry https://registry.npm.taobao.org
RUN pnpm i

ADD . /code
RUN npm run build && npm run oss:script

# 选择更小体积的基础镜像
FROM nginx:alpine
ADD nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder code/dist /usr/share/nginx/html