FROM heroku/heroku:18-build

# Fixes some weird terminal issues such as broken clear / CTRL+L.
ENV TERM=linux
ENV DEBIAN_FRONTEND=noninteractive

# Makes `heroku local` always start on the same port...
ENV PORT=8081

# Installing common utilities...
RUN apt-get update \
  && apt-get install -y \
  nano \
  vim \
  software-properties-common \
  git \
  sudo \
  p7zip-full \
  keychain \
  libaprutil1 \
  net-tools

# Installing httpd, PHP and PHP-FPM...
COPY ./local/bin/* /usr/local/bin/
COPY ./local/sbin/* /usr/local/sbin/
COPY ./php/* /etc/php/
COPY ./local/lib/php/* /usr/local/lib/php/
COPY ./local/lib/apache2/* /usr/local/lib/apache2/
COPY ./apache2/* /etc/apache2/
COPY ./php-fpm/* /usr/etc/
RUN mkdir -p /var/run/apache2 /var/log/apache2

# Installing Composer...
RUN wget -O /usr/local/bin/composer https://getcomposer.org/download/1.8.5/composer.phar \
  && chown root:root /usr/local/bin/composer \
  && chmod 0755 /usr/local/bin/composer

# Installing NodeJS...
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - \
  && apt-get install -y nodejs

# Installing MySQL...
RUN apt-get update \
  && apt-get install -y mysql-server \
  && rm -rf /etc/mysql \
  && rm -rf /var/lib/mysql \
  && mkdir /etc/mysql \
  && mkdir /var/run/mysqld \
  && chmod -R 777 /var/log/mysql \
  && chmod -R 777 /var/run/mysqld
COPY ./mysql/* /etc/mysql/

# Installing Yarn...
RUN sudo npm install -g yarn

# Installing heroku CLI...
RUN curl https://cli-assets.heroku.com/install.sh | sh

# See https://github.com/Yelp/dumb-init.
RUN dumb_init_url=https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 && \
  wget -O /usr/local/bin/dumb-init $dumb_init_url
RUN chmod +x /usr/local/bin/dumb-init
ENTRYPOINT ["/usr/local/bin/dumb-init"]

# Adding bash-related configuration files...
COPY ./home/* /home/

# Adding main commands...
COPY ./sbin/* /sbin/

RUN mkdir -p /home/developer
WORKDIR /home/developer/

EXPOSE 3000 3306 8080 8081

CMD /sbin/entrypoint.sh
