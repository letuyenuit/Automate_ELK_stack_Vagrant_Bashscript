sudo apt install mysql-server -y
sudo systemctl enable mysql.service
sudo systemctl start mysql.service
sudo sed -i 's/^#port[ \t]*=[ \t]*3306/port = 3306/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i 's/^bind-address[ \t]*=[ \t]*127\.0\.0\.1/bind-address            = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';
FLUSH PRIVILEGES;
EOF

sudo cat << 'EOF' > /home/vagrant/create_user.sh
#!/bin/bash

# MySQL credentials
MYSQL_ROOT_USER="root"
MYSQL_ROOT_PASSWORD="root"

# New user credentials
NEW_USER="letuyen"
NEW_USER_PASSWORD="letuyen"
SQL_QUERY="CREATE USER '${NEW_USER}'@'%' IDENTIFIED BY '${NEW_USER_PASSWORD}'; GRANT ALL PRIVILEGES ON *.* TO '${NEW_USER}'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
sudo mysql -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASSWORD} -e "${SQL_QUERY}"
echo "User '${NEW_USER}' với mật khẩu '${NEW_USER_PASSWORD}' đã được tạo thành công."

# Access log
SQL_QUERY_LOG="SET GLOBAL general_log_file='/var/log/mysql/general.log';SET GLOBAL log_output = 'FILE';SET GLOBAL general_log = 'ON';"
sudo mysql -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASSWORD} -e "${SQL_QUERY_LOG}"
EOF

sudo chmod +x /home/vagrant/create_user.sh

sudo /home/vagrant/create_user.sh


# install Filebeat
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update && sudo apt-get install filebeat


# Install sshpass
sudo apt-get install sshpass

#Get certs remote 
sshpass -p 'vagrant' scp -o StrictHostKeyChecking=no -r vagrant@192.168.56.50:/home/vagrant/authdir /home/vagrant
# Configure Filebeat

CONFIG_CONTENT=$(cat << 'EOF'
filebeat.inputs:
  - type: filestream
    id: my-filestream-id
    enabled: false
    paths:
      - /var/log/*.log
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
setup.dashboards.enabled: true
setup.kibana:
  host: "http://192.168.56.50:5601"
output.elasticsearch:
  hosts: ["https://192.168.56.50:9200"]
  username: "elastic"
  password: "elastic"
  ssl:
    enabled: true
    ca_trusted_fingerprint: "{{fingerprint}}"
processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
EOF
)
echo "$CONFIG_CONTENT" | sudo tee /etc/filebeat/filebeat.yml > /dev/null

sudo filebeat modules enable mysql

# Configure Filebeat Mysql
sudo cat << EOF > /etc/filebeat/modules.d/mysql.yml
- module: mysql
  error:
    enabled: true
    var.paths: ["/var/log/mysql/error.log*"]
  slowlog:
    enabled: true
    var.paths: ["/var/log/mysql/general.log"]
EOF



#Install and config Metricbeat
sudo apt-get update && sudo apt-get install metricbeat

METRICBEAT=$(cat << 'EOF'
metricbeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false
setup.template.settings:
  index.number_of_shards: 1
  index.codec: best_compression
setup.dashboards.enabled: true
setup.kibana:
  host: "http://192.168.56.50:5601"
output.elasticsearch:
  hosts: ["https://192.168.56.50:9200"]
  username: "elastic"
  password: "elastic"
  ssl:
    enabled: true
    ca_trusted_fingerprint: "{{fingerprint}}"
processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
EOF
)
echo "$METRICBEAT" | sudo tee /etc/metricbeat/metricbeat.yml > /dev/null

sudo metricbeat modules enable mysql
sudo cat << EOF > /etc/metricbeat/modules.d/nginx.yml
metricbeat.modules:
- module: mysql
  metricsets:
    - status
    - galera_status
    - performance
    - query
  period: 10s

  # Host DSN should be defined as "user:pass@tcp(127.0.0.1:3306)/"
  # or "unix(/var/lib/mysql/mysql.sock)/",
  # or another DSN format supported by <https://github.com/Go-SQL-Driver/MySQL/>.
  # The username and password can either be set in the DSN or using the username
  # and password config options. Those specified in the DSN take precedence.
  hosts: ["letuyen:letuyen@tcp(192.168.56.70:3306)/"]

  # Username of hosts. Empty by default.
  #username: root

  # Password of hosts. Empty by default.
  #password: secret

  # By setting raw to true, all raw fields from the status metricset will be added to the event.
  #raw: false

  # Optional SSL/TLS. By default is false.
  #ssl.enabled: true

  # List of root certificates for SSL/TLS server verification
  #ssl.certificate_authorities: ["/etc/pki/root/ca.crt"]

  # Certificate for SSL/TLS client authentication
  #ssl.certificate: "/etc/pki/client/cert.crt"

  # Client certificate key file
  #ssl.key: "/etc/pki/client/cert.key"
EOF

PASSWORD=elastic
FINGERPRINT=$(cat /home/vagrant/authdir/fingerprint)
sudo sed -i "s/{{fingerprint}}/$FINGERPRINT/g" /etc/filebeat/filebeat.yml
sudo sed -i "s/{{fingerprint}}/$FINGERPRINT/g" /etc/metricbeat/metricbeat.yml