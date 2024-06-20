Vagrant.configure("2") do |config|
  config.vm.provision "shell", inline: <<-SHELL
      sudo apt update
    SHELL

  config.vm.define "elk" do |elk|
    elk.vm.box = "ubuntu/focal64"
    elk.vm.hostname = "elk"
    elk.vm.network "private_network", ip: "192.168.56.50"
    elk.vm.provider "virtualbox" do |vb|
        vb.memory = 8192
        vb.cpus = 2
    end
    elk.vm.provision "shell", path: "cluster.sh"
  end

  config.vm.define "webserver" do |webserver|
    webserver.vm.box = "ubuntu/focal64"
    webserver.vm.hostname = "webserver"
    webserver.vm.network "private_network", ip: "192.168.56.60"
    webserver.vm.provider "virtualbox" do |vb|
        vb.memory = 3072
        vb.cpus = 1
    end
    webserver.vm.provision "shell", path: "nginx.sh"
  end

  config.vm.define "mysql" do |mysql|
    mysql.vm.box = "ubuntu/focal64"
    mysql.vm.hostname = "mysql"
    mysql.vm.network "private_network", ip: "192.168.56.70"
    mysql.vm.provider "virtualbox" do |vb|
        vb.memory = 2048
        vb.cpus = 1
    end
    mysql.vm.provision "shell", path: "mysql.sh"
  end
  config.vm.define "datanode" do |datanode|
    datanode.vm.box = "ubuntu/focal64"
    datanode.vm.hostname = "datanode"
    datanode.vm.network "private_network", ip: "192.168.56.80"
    datanode.vm.provider "virtualbox" do |vb|
        vb.memory = 2048
        vb.cpus = 1
    end
    datanode.vm.synced_folder "./token.txt", "/tmp/token.txt"
    datanode.vm.provision "shell", path: "datanode.sh"
  end
end