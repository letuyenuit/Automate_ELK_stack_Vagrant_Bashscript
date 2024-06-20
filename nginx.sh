#!/bin/bash

# install Nginx
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx


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
output.elasticsearch.index: "webserver-%{[agent.version]}"
setup.template.name: "webserver-%{[agent.version]}"
setup.template.pattern: "webserver-%{[agent.version]}"
EOF
)
echo "$CONFIG_CONTENT" | sudo tee /etc/filebeat/filebeat.yml > /dev/null

sudo filebeat modules enable nginx

# Configure Filebeat Nginx Webserver
sudo cat << EOF > /etc/filebeat/modules.d/nginx.yml
- module: nginx
  # Access logs
  access:
    enabled: true
    var.paths: ["/var/log/nginx/access.log"]

  # Error logs
  error:
    enabled: true
    var.paths: ["/var/log/nginx/error.log"]
EOF


PASSWORD=elastic
FINGERPRINT=$(cat /home/vagrant/authdir/fingerprint)
sudo sed -i "s/{{fingerprint}}/$FINGERPRINT/g" /etc/filebeat/filebeat.yml


#load ingest
# sudo filebeat setup -e

# start Filebeat
# sudo systemctl daemon-reload
# sudo systemctl enable filebeat
# sudo systemctl start filebeat