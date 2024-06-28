FROM golang:1.21 as go-builder

WORKDIR /work
ENV GOPROXY=https://goproxy.cn,direct
COPY backend/go.mod .
COPY backend/go.sum .
RUN go mod download
COPY backend .
RUN CGO_ENABLED=0 go build -a -v -ldflags="-w" -o server .

FROM node:20.5-alpine

RUN apk update
RUN apk add nginx supervisor curl

RUN echo -e "                                                                   \n\
server {                                                                        \n\
    listen 80;                                                                  \n\
                                                                                \n\
    location /api/ {                                                            \n\
        proxy_pass http://localhost:8080;                                       \n\
    }                                                                           \n\
    location /docs {                                                            \n\
        proxy_pass http://localhost:3000;                                       \n\
    }                                                                           \n\
    location /blazehttp {                                                       \n\
        root /app/;                                                             \n\
        try_files \$uri =404;                                                    \n\
    }                                                                           \n\
    location /release {                                                         \n\
        root /app/;                                                             \n\
        try_files \$uri =404;                                                    \n\
    }                                                                           \n\
    location /sitemap.xml {                                                     \n\
        root /srv/website/public;                                               \n\
    }                                                                           \n\
    location /sitemap-0.xml {                                                   \n\
        root /srv/website/public;                                               \n\
    }                                                                           \n\
    location /robots.txt {                                                      \n\
        root /srv/website/public;                                               \n\
    }                                                                           \n\
    location /googlef97f8402f9139518.html {                                     \n\
        root /srv/website/public;                                               \n\
    }                                                                           \n\
    location /BingSiteAuth.xml {                                                 \n\
        root /srv/website/public;                                               \n\
    }                                                                           \n\
    location / {                                                                \n\
        rewrite /posts/guide_introduction /docs/ permanent;                     \n\
        rewrite /posts/guide_install /docs/guide/install permanent;             \n\
        rewrite /docs/上手指南/guide_install /docs/guide/install permanent;      \n\
        rewrite /posts/guide_login /docs/guide/login permanent;                 \n\
        rewrite /docs/上手指南/guide_login /docs/guide/login permanent;          \n\
        rewrite /posts/guide_config /docs/guide/config permanent;               \n\
        rewrite /docs/上手指南/guide_config /docs/guide/config permanent;        \n\
        rewrite /posts/guide_test /docs/guide/test permanent;                   \n\
        rewrite /docs/上手指南/guide_test /docs/guide/test permanent;            \n\
        rewrite /posts/guide_upgrade /docs/guide/upgrade permanent;             \n\
        rewrite /docs/上手指南/guide_upgrade /docs/guide/upgrade permanent;      \n\
        rewrite /posts/faq_install /docs/faq/install permanent;                 \n\
        rewrite /docs/常见问题排查/faq_install /docs/faq/install permanent;       \n\
        rewrite /posts/faq_login /docs/faq/login permanent;                     \n\
        rewrite /docs/常见问题排查/faq_login /docs/faq/login permanent;           \n\
        rewrite /posts/faq_access /docs/guide/config permanent;                 \n\
        rewrite /docs/常见问题排查/faq_access /docs/guide/config permanent;       \n\
        rewrite /posts/faq_config /docs/faq/config permanent;                   \n\
        rewrite /docs/常见问题排查/faq_config /docs/faq/config permanent;         \n\
        rewrite /posts/faq_other /docs/faq/other permanent;                     \n\
        rewrite /docs/常见问题排查/faq_other /docs/faq/other permanent;           \n\
        rewrite /posts/about_syntaxanalysis /docs/about/syntaxanalysis permanent;         \n\
        rewrite /docs/关于雷池/about_syntaxanalysis /docs/about/syntaxanalysis permanent;  \n\
        rewrite /posts/about_challenge /docs/about/challenge permanent;         \n\
        rewrite /docs/关于雷池/about_challenge /docs/about/challenge permanent;  \n\
        rewrite /posts/about_changelog /docs/about/changelog permanent;         \n\
        rewrite /docs/关于雷池/about_changelog /docs/about/changelog permanent;  \n\
        rewrite /posts/about_chaitin /docs/about/chaitin permanent;             \n\
        rewrite /docs/关于雷池/about_chaitin /docs/about/chaitin permanent;      \n\
        rewrite /docs/faq/access /docs/guide/config permanent;                  \n\
        rewrite /docs/faq/config /docs/guide/config permanent;                  \n\
        proxy_pass http://127.0.0.1:3001;                                       \n\
    }                                                                           \n\
}                                                                               \n\
" > /etc/nginx/http.d/default.conf
RUN sed -i 's/access_log/access_log off; #/' /etc/nginx/nginx.conf
# RUN nginx -t

RUN mkdir /etc/supervisor.d
RUN echo -e "                       \n\
[program:doc]                       \n\
command     = npm run serve         \n\
directory   = /srv/documents        \n\
                                    \n\
[program:front]                     \n\
command     = npm start             \n\
directory   = /srv/website/cn       \n\
                                    \n\
[program:server]                    \n\
command     = /srv/server           \n\
" > /etc/supervisor.d/safeline.ini

COPY --from=go-builder /work/server /srv/server

COPY documents /srv/documents
WORKDIR /srv/documents
RUN npm ci; npm run build
# npm run serve

ENV TARGET=http://localhost:8080
COPY website /srv/website
WORKDIR /srv/website/cn
RUN npm ci; npm run build
# npm start

COPY release /app/release
# 需要提前准备好 blazehttp 的文件，5 个不通系统执行文件和 1 个 case 压缩包
COPY blazehttp/build /app/blazehttp

WORKDIR /srv

# ENV GITHUB_TOKEN=$GITHUB_TOKEN
# ENV HTTPS_PROXY=$HTTPS_PROXY

CMD supervisord; nginx -g 'daemon off;'
