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
