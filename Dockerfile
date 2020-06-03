FROM lsiobase/alpine:3.12 as buildstage

# build variables
ARG PWNDROP_RELEASE

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache \
	curl \
	g++ \
	gcc \
	git \
	go \
	tar

RUN \
echo "**** fetch source code ****" && \
 if [ -z ${PWNDROP_RELEASE+x} ]; then \
	PWNDROP_RELEASE=$(curl -sX GET "https://api.github.com/repos/kgretzky/pwndrop/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 mkdir -p \
	/tmp/pwndrop && \
 curl -o \
 /tmp/pwndrop-src.tar.gz -L \
	"https://github.com/kgretzky/pwndrop/archive/${PWNDROP_RELEASE}.tar.gz" && \
 tar xf \
 /tmp/pwndrop-src.tar.gz -C \
	/tmp/pwndrop --strip-components=1 && \
 echo "**** compile pwndrop  ****" && \
 cd /tmp/pwndrop && \
 go build -ldflags="-s -w" \
	-o /app/pwndrop/pwndrop \
	-mod=vendor \
	main.go && \
 cp -r ./www /app/pwndrop/admin

############## runtime stage ##############
FROM lsiobase/alpine:3.12

# set version label
ARG BUILD_DATE
ARG VERSION
ARG PWNDROP_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# add pwndrop
COPY --from=buildstage /app/pwndrop/ /app/pwndrop/

# add local files
COPY /root /

# ports and volumes
EXPOSE 8080 4443
