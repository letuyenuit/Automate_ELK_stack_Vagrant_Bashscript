#!/bin/bash
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl restart ssh

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
sudo apt-get install apt-transport-https
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# install Elasticsearch
sudo apt-get update && sudo apt-get install elasticsearch -y

# configure Elasticsearch
sudo sed -i 's/#cluster.name:.*$/cluster.name: control-monitor/' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#network.host:.*$/network.host: 192.168.56.50/g' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#http.port:.*$/http.port: 9200/g' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#transport.host:.*$/transport.host: 0.0.0.0/g' /etc/elasticsearch/elasticsearch.yml
# start Elasticsearch
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch


# install Kibana
sudo apt-get install kibana -y

# configure Kibana
sudo sed -i 's/#server.port:.*$/server.port: 5601/g' /etc/kibana/kibana.yml
sudo sed -i 's/#server.host:.*$/server.host: 192.168.56.50/g' /etc/kibana/kibana.yml
# start Kibana
sudo systemctl daemon-reload
sudo systemctl enable kibana
sudo systemctl start kibana

# install Logstash
sudo apt-get install logstash -y

# configure Logstash
sudo sed -i 's/#api.http.host:.*$/api.http.host: 192.168.56.50/g' /etc/logstash/logstash.yml
# start Logstash
sudo systemctl daemon-reload
sudo systemctl enable logstash
sudo systemctl start logstash

sudo mkdir -p /home/vagrant/authdir
sudo chmod 777 /home/vagrant/authdir

sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i <<EOF
y
elastic
elastic
EOF

sudo openssl x509 -in /etc/elasticsearch/certs/http_ca.crt -sha256 -fingerprint | grep SHA256 | sed 's/://g' | cut -d'=' -f2 > /home/vagrant/authdir/fingerprint

