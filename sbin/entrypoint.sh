#!/bin/bash

# fail hard
set -o pipefail
# fail harder
set -eu

# Relocating home directory, no matter which logged into host (this is important)...
export HOME=/home/developer

# Ensures `.bash_profile` file exists to prevent any error.
touch ~/.bash_profile

init_mysql() {
  mysql --user=root <<_EOF_
UPDATE mysql.user SET authentication_string=PASSWORD('root') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
CREATE USER 'developer'@'%' IDENTIFIED BY 'docker';
GRANT ALL PRIVILEGES ON *.* TO 'developer'@'%' WITH GRANT OPTION;
_EOF_
}

start_mysql() {
  if [ ! -d "/home/developer/mysql" ]; then
    mysqld --initialize-insecure &>/dev/null
    mysqld&
    # As MySQL server can take some time to start-up, we try to initialize the DB as long as we fail.
    while :
    do
      init_mysql 2>/dev/null && break || sleep 1
    done
  else
    mysqld&
  fi
}

# Starting MySQL server...
start_mysql

# Starting httpd server...
php-fpm --nodaemonize&
httpd -D NO_DETACH -c "Include /etc/apache2/default.conf" &

# Protecting localhost:8080...
printf "developer:$(openssl passwd -crypt $PASSWORD)\n" > ~/.htpasswd
echo -e $"AuthType Basic\nAuthName \"Developer\"\nAuthUserFile $HOME/.htpasswd\nRequire valid-user" > ~/.htaccess

# Adding symlink to checklist...
if [ -L "$HOME/checklist" ]; then
  rm ~/checklist
fi
ln -s /var/www/checklist ~/checklist

# Permanently adding SSH key in keychain...
rm -rf ~/.keychain
echo -e $"/usr/bin/keychain $HOME/.ssh/id_rsa\nsource $HOME/.keychain/$HOSTNAME-sh" > ~/.bash_profile

/sbin/start
