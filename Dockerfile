
FROM arm64v8/ubuntu:20.04

COPY qemu-aarch64-static /usr/bin

ENV DEBIAN_FRONTEND=noninteractive

# Install git, supervisor, VNC, & X11 packages
RUN set -xe; \
    apt-get update; \
    apt-get install -y \
      bash \
      python \
      wget \
      sudo \
      cron \
      git \
      net-tools \
      x11vnc \
      xterm \
      xvfb

RUN set -xe; \
    apt-get update; \
    apt-get install -y openbox

RUN addgroup iptvboss \
    && adduser --home /home/iptvboss --gid 1000 --shell /bin/bash iptvboss \
    && echo "iptvboss:iptvboss" | /usr/sbin/chpasswd \
    && echo "iptvboss ALL=NOPASSWD: ALL" >> /etc/sudoers \
    && adduser iptvboss crontab

USER iptvboss

ENV USER=iptvboss \
    DISPLAY=:0 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    HOME=/home/iptvboss \
    TERM=xterm \
    SHELL=/bin/bash \
    LD_LIBRARY_PATH=/opt/jdk-15.0.1-full/lib \
    PATH_TO_FX=/opt/jdk-15.0.1-full/lib \
    DISPLAY_WIDTH=1280 \
    DISPLAY_HEIGHT=960 \
    VNC_PORT=5900 \
    VNC_RESOLUTION=1280x960 \
    VNC_COL_DEPTH=24  \
    NOVNC_PORT=5800 \
    NOVNC_HOME=/home/iptvboss/noVNC 

RUN set -xe \
  && mkdir -p $NOVNC_HOME/utils/websockify \
  && wget -qO- https://github.com/novnc/noVNC/archive/v1.1.0.tar.gz | tar xz --strip 1 -C $NOVNC_HOME \
  && wget -qO- https://github.com/novnc/websockify/archive/v0.9.0.tar.gz | tar xzf - --strip 1 -C $NOVNC_HOME/utils/websockify \
  && chmod +x -v $NOVNC_HOME/utils/*.sh \
  && ln -s $NOVNC_HOME/vnc.html $NOVNC_HOME/index.html

RUN echo "15 4 * * * /home/iptvboss/appinit.sh > /home/iptvboss/cron.log 2>&1"| crontab -

EXPOSE 5800
VOLUME ["/app"]

COPY src/run_init /usr/bin/
COPY src/ui.js $NOVNC_HOME/app/

CMD ["bash", "/usr/bin/run_init"]
