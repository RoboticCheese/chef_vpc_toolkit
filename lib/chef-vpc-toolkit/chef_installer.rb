require 'rubygems'
require 'json'
require 'yaml'

module ChefVPCToolkit

module ChefInstaller
CHEF_INSTALL_FUNCTIONS=File.dirname(__FILE__) + "/chef_functions.bash"

def self.load_configs

	config_file=CHEF_VPC_PROJECT + File::SEPARATOR + "config" + File::SEPARATOR + "chef_installer.yml"

	if File.exists?(config_file) then
		return YAML.load_file(config_file)
	else
		raise "The config/chef_installer.conf file is missing."
	end

end

def self.get_cookbook_repos(options)
	cookbook_repos_config=options["chef_cookbook_repos"]
	return "" if cookbook_repos_config.nil?
	if cookbook_repos_config.respond_to?(:inject) then
		return options["chef_cookbook_repos"].inject { |sum, c| sum + " " + c }
	else
		return cookbook_repos_config.to_s
	end
end

def self.install_chef_script(install_type="CLIENT", os_type="")
	return "" if os_type.nil? or os_type.empty?

	return %{
	#{IO.read(File.dirname(__FILE__) + "/chef_bootstrap/#{os_type}.bash")}
	install_chef "#{install_type}"
	}

end

# validate the chef.json config file by parsing it
def self.validate_json(options)

	Util.raise_if_nil_or_empty(options, "chef_json_file")
	begin
		JSON.parse(IO.read(options["chef_json_file"]))
	rescue Exception => e
		puts "Failed to parse Chef JSON config file:"
		puts ""
		raise		
	end

	if not options["databags_json_file"].nil? and not options["databags_json_file"].empty?
		begin
			JSON.parse(IO.read(options["databags_json_file"]))
		rescue Exception => e
			puts "Failed to parse Databag JSON config file:"
			puts ""
			raise		
		end
	end

end

def self.install_chef_server(options, machine_os_types)

Util.raise_if_nil_or_empty(options, "ssh_gateway_ip")
Util.raise_if_nil_or_empty(options, "chef_json_file")
Util.raise_if_nil_or_empty(options, "chef_server_name")

# should we install a Chef client on the server?
json=JSON.parse(IO.read(options["chef_json_file"]))
configure_client_script=""
start_client_script=""
if json.has_key?(options["chef_server_name"]) then
	configure_client_script="configure_chef_client '#{options['chef_server_name']}' '' '#{options['chef_interval']}'"
	start_client_script="start_chef_client"
end
knife_add_empty_nodes_script=""
json.each_pair do |node_name, node_json|
	run_list_json=JSON.generate([])
	node_json.delete("run_list")
	attributes_json=node_json.to_json.to_s
	knife_add_empty_nodes_script+="knife_add_node '#{node_name}' '#{run_list_json}' '#{attributes_json}'\n"
end

cookbook_urls=self.get_cookbook_repos(options)
os_type=machine_os_types[options['chef_server_name']]

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
echo "Installing Chef server and client on: $HOSTNAME"
EOF_BASH
EOF_GATEWAY
}
puts data

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
#{IO.read(File.dirname(__FILE__) + "/cloud_files.bash")}
#{install_chef_script('SERVER', os_type)}
EOF_BASH
EOF_GATEWAY
}

puts data

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
echo "Done installing Chef server on: $HOSTNAME"
echo "Configuring Chef server on: $HOSTNAME"
EOF_BASH
EOF_GATEWAY
}
puts data

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
#{IO.read(CHEF_INSTALL_FUNCTIONS)}
#{IO.read(File.dirname(__FILE__) + "/cloud_files.bash")}
mkdir -p /root/cookbook-repos
configure_chef_server
EOF_BASH
EOF_GATEWAY
}
puts data

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
echo "Done configuring Chef server on: $HOSTNAME"
echo "Configuring Chef client on: $HOSTNAME"
EOF_BASH
EOF_GATEWAY
}
puts data

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
#{IO.read(CHEF_INSTALL_FUNCTIONS)}
#{IO.read(File.dirname(__FILE__) + "/cloud_files.bash")}
#{configure_client_script}
EOF_BASH
EOF_GATEWAY
}
puts data

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
echo "Done configuring Chef client on: $HOSTNAME"
echo "Configuring knife on: $HOSTNAME"
EOF_BASH
EOF_GATEWAY
}
puts data

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
#{IO.read(CHEF_INSTALL_FUNCTIONS)}
#{IO.read(File.dirname(__FILE__) + "/cloud_files.bash")}
configure_knife "#{options["knife_editor"]}"
EOF_BASH
EOF_GATEWAY
}
puts data

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
echo "Done configuring knife on: $HOSTNAME"
echo "Uploading cookbooks and roles to Chef server on: $HOSTNAME"
EOF_BASH
EOF_GATEWAY
}
puts data

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
#{IO.read(CHEF_INSTALL_FUNCTIONS)}
#{IO.read(File.dirname(__FILE__) + "/cloud_files.bash")}
knife_upload_cookbooks_and_roles
EOF_BASH
EOF_GATEWAY
}
puts data

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
echo "Done uploading cookbooks and roles to Chef server on: $HOSTNAME"
echo "Adding nodes to Chef server on: $HOSTNAME"
EOF_BASH
EOF_GATEWAY
}
puts data

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
#{IO.read(CHEF_INSTALL_FUNCTIONS)}
#{IO.read(File.dirname(__FILE__) + "/cloud_files.bash")}
#{knife_add_empty_nodes_script}
EOF_BASH
EOF_GATEWAY
}
puts data

#start_chef_server

return client_validation_key(options)

end

def self.client_validation_key(options)

client_validation_key=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
#{IO.read(CHEF_INSTALL_FUNCTIONS)}
print_client_validation_key
EOF_BASH
EOF_GATEWAY
}

raise "Client validation key is blank." if client_validation_key.nil? or client_validation_key.empty?

return client_validation_key

end

def self.install_chef_clients(options, client_validation_key, os_types)

	# configure Chef clients on each node
	json=JSON.parse(IO.read(options['chef_json_file']))
	json.each_pair do |hostname, json_hash|
		if hostname != options['chef_server_name']
			install_chef_client(options, hostname, client_validation_key, os_types[hostname])
		end
	end

end

def self.install_chef_client(options, client_name, client_validation_key, os_type)

	puts "Installing Chef client on: #{client_name}"

	data=%x{
	ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
	if ! grep -c "#{client_name}" /etc/hosts &> /dev/null; then
		echo "Client '#{client_name}' doesn't exist."
		exit 0
	fi
	ssh #{client_name} bash <<-"EOF_BASH"
	#{IO.read(File.dirname(__FILE__) + "/cloud_files.bash")}
	#{IO.read(CHEF_INSTALL_FUNCTIONS)}
	#{install_chef_script('CLIENT', os_type)}
	EOF_BASH
	EOF_GATEWAY
	}
	puts data

	puts "Done installing chef client on: #{client_name}"
	puts "Configuring chef client on: #{client_name}"

	data=%x{
	ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
	if ! grep -c "#{client_name}" /etc/hosts &> /dev/null; then
		echo "Client '#{client_name}' doesn't exist."
		exit 0
	fi
	ssh #{client_name} bash <<-"EOF_BASH"
	#{IO.read(File.dirname(__FILE__) + "/cloud_files.bash")}
	#{IO.read(CHEF_INSTALL_FUNCTIONS)}
	configure_chef_client '#{options['chef_server_name']}' '#{client_validation_key}' '#{options['chef_interval']}'
	EOF_BASH
	EOF_GATEWAY
	}
	puts data

	puts "Done configuring chef client on #{client_name}"
end

def self.run_chef_clients_once(options)
json=JSON.parse(IO.read(options['chef_json_file']))
json.each_pair do |hostname, json_hash|
    run_chef_client_once(options, hostname)
end

end

def self.run_chef_client_once(options, client_name)
puts "Running Chef client once on: #{client_name} to populate ohai attributes"
data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
if ! grep -c "#{client_name}" /etc/hosts &> /dev/null; then
    echo "Client '#{client_name}' doesn't exist."
    exit 0
fi
ssh #{client_name} bash <<-"EOF_BASH"
#{IO.read(File.dirname(__FILE__) + "/cloud_files.bash")}
#{IO.read(CHEF_INSTALL_FUNCTIONS)}
run_chef_client_once
EOF_BASH
EOF_GATEWAY
}
puts data
puts "Done with initial chef client run on #{client_name}"
end

def self.start_chef_clients(options)
json=JSON.parse(IO.read(options['chef_json_file']))
json.each_pair do |hostname, json_hash|
    start_chef_client(options, hostname)
end
end

def self.start_chef_client(options, client_name)
puts "Starting Chef client on: #{client_name}"
data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
if ! grep -c "#{client_name}" /etc/hosts &> /dev/null; then
    echo "Client '#{client_name}' doesn't exist."
    exit 0
fi
ssh #{client_name} bash <<-"EOF_BASH"
#{IO.read(File.dirname(__FILE__) + "/cloud_files.bash")}
#{IO.read(CHEF_INSTALL_FUNCTIONS)}
start_chef_client
EOF_BASH
EOF_GATEWAY
}
puts data
end

def self.create_databags(options)

Util.raise_if_nil_or_empty(options, "ssh_gateway_ip")

if options["databags_json_file"].nil? or options["databags_json_file"].empty?
puts "No databag config file specified."
return
end
printf "Creating databags..."
STDOUT.flush

if not File.exists?(options["databags_json_file"]) then
	raise "Databags json file is missing: #{options["databags_json_file"]}."
end

json=JSON.parse(IO.read(options["databags_json_file"]))

databag_cmds=""

json.each_pair do |bag_name, items_json|
	databag_cmds+="knife data bag delete '#{bag_name}' -y &> /dev/null \n"
	databag_cmds+="knife data bag create '#{bag_name}' -y \n"

	items_json.each do |item_json|

	item_id=item_json["id"]
	raise "Databags json missing item ID." if item_id.nil? or item_id.empty?
	databag_cmds+="knife_create_databag '#{bag_name}' '#{item_id}' '#{item_json.to_json.to_s}'\n"
	end

data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
#{IO.read(CHEF_INSTALL_FUNCTIONS)}
#{databag_cmds}
EOF_GATEWAY
}

end

puts "OK."

end

def self.knife_add_runlists(options)
json=JSON.parse(IO.read(options["chef_json_file"]))
json.each_pair do |node_name, node_json|
	knife_add_runlist(options, node_name)
end
end

def self.knife_add_runlist(options, client_name)
knife_add_to_runlist_script=""
json=JSON.parse(IO.read(options["chef_json_file"]))
node_json=json[client_name]
run_list=node_json['run_list']
run_list.each do |item|
knife_add_to_runlist_script+="knife_add_to_run_list #{client_name} #{item}\n"
end
data = %x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
#{IO.read(CHEF_INSTALL_FUNCTIONS)}
#{knife_add_to_runlist_script}
EOF_BASH
EOF_GATEWAY
}
puts data
end

def self.knife_readd_node(options, client_name)

Util.raise_if_nil_or_empty(options, "ssh_gateway_ip")
Util.raise_if_nil_or_empty(options, "chef_json_file")
puts "Readding #{client_name} node with attributes and run list"
json=JSON.parse(IO.read(options["chef_json_file"]))
node_json=json[client_name]
run_list=node_json['run_list'].inspect
node_json.delete("run_list")
attributes=node_json.to_json.to_s
data=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
#{IO.read(CHEF_INSTALL_FUNCTIONS)}
knife_delete_node '#{client_name}'
knife_add_node '#{client_name}' '#{run_list}' '#{attributes}'
EOF_GATEWAY
}

end

def self.tail_log(gateway_ip, server_name, log_file="/var/log/chef/client.log", num_lines="100")
	%x{ssh -o "StrictHostKeyChecking no" root@#{gateway_ip} ssh #{server_name} tail -n #{num_lines} #{log_file}}
end


def self.pull_cookbook_repos(options, local_dir="#{CHEF_VPC_PROJECT}/cookbook-repos/", remote_directory="/root/cookbook-repos")
	$stdout.printf "Pulling remote Chef cookbook repositories..."
	system("rsync -azL root@#{options['ssh_gateway_ip']}:#{remote_directory}/* '#{local_dir}'")
	puts "OK"
end

def self.rsync_cookbook_repos(options, local_dir="#{CHEF_VPC_PROJECT}/cookbook-repos/", remote_directory="/root/cookbook-repos")

	if File.exists?(local_dir) then
		$stdout.printf "Pushing local Chef cookbook repositories..."
		configs=Util.load_configs
		%x{ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_SSH"
			mkdir -p #{remote_directory}
			if [ -f /usr/bin/yum ]; then
				rpm -q rsync &> /dev/null || yum install -y -q rsync
			else
				dpkg -L rsync > /dev/null 2>&1 || apt-get install -y --quiet rsync > /dev/null 2>&1
			fi
		EOF_SSH
		}
		system("rsync -azL '#{local_dir}' root@#{options['ssh_gateway_ip']}:#{remote_directory}")
		puts "OK"
	end

	cookbook_urls=self.get_cookbook_repos(options)

	data=%x{
	ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_SSH"
	#{IO.read(File.dirname(__FILE__) + "/cloud_files.bash")}
	#{IO.read(CHEF_INSTALL_FUNCTIONS)}

	if [ -n "#{cookbook_urls}" ]; then
		download_cookbook_repos "#{cookbook_urls}"
	fi

	if [ -f /root/.chef/knife.rb ]; then
		echo -n "Uploading cookbooks and roles..."
		knife_upload_cookbooks_and_roles
		echo "OK"
	fi

	EOF_SSH
	}
	puts data

end

def self.poll_clients(options, client_names, timeout=600, restart_timeout=600, restart_once_on_failure="")

output=%x{
ssh -o "StrictHostKeyChecking no" root@#{options['ssh_gateway_ip']} bash <<-"EOF_GATEWAY"
ssh #{options['chef_server_name']} bash <<-"EOF_BASH"
#{IO.read(CHEF_INSTALL_FUNCTIONS)}
poll_chef_client_online "#{client_names}" "#{timeout}" "#{restart_timeout}" "#{restart_once_on_failure}"
EOF_BASH
EOF_GATEWAY
}
retval=$?
puts output
return retval.success?

end

end

end
