#
# Author:: Ryan C. Creasey (<rcreasey@ign.com>)
# Copyright:: Copyright (c) 2010 IGN Entertainment
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class String
  def red; color(self, "\e[1m\e[31m"); end
  def green; color(self, "\e[1m\e[32m"); end
  def yellow; color(self, "\e[1m\e[33m"); end
  def blue; color(self, "\e[1m\e[34m"); end
  def pur; color(self, "\e[1m\e[35m"); end
  def color(text, color_code)  "#{color_code}#{text}\e[0m" end
end

require 'chef/knife'
require 'json'

class Chef
  class Knife
    class XenServerCreate < Knife

      banner "knife xen server create [RUN LIST...] (options)"

      option :server_name,
        :short => "-N NAME",
        :long => "--server-name NAME",
        :description => "The server name"

      option :home_hypervisor,
        :short => "-h HYPERVISOR",
        :long => "--home-hypervisor HYPERVISOR",
        :description => "The name of the hypervisor to start the new server on"

      option :xenserver_password,
        :short => "-K PASSWORD",
        :long => "--xenserver-password PASSWORD",
        :description => "Your xenserver password",
        :proc => Proc.new { |key| Chef::Config[:knife][:xenserver_password] = key }

      option :xenserver_username,
        :short => "-A USERNAME",
        :long => "--xenserver-username USERNAME",
        :description => "Your xenserver username",
        :proc => Proc.new { |username| Chef::Config[:knife][:xenserver_username] = username }

      option :xenserver_pool_master,
        :short => "-P HOST",
        :long => "--xenserver-pool-master HOST",
        :description => "Your xenserver pool master hostname",
        :proc => Proc.new { |pool_master| Chef::Config[:knife][:xenserver_pool_master] = pool_master }

      def h
        @highline ||= HighLine.new
      end

      def run
        require 'fog'
        require 'highline'
        require 'highline/import'
        require 'net/ssh/multi'
        require 'readline'
        require 'ruby-debug'

        xenserver = Fog::Xenserver.new(
          :xenserver_username    => Chef::Config[:xenserver][:username],
          :xenserver_password    => Chef::Config[:xenserver][:password],
          :xenserver_pool_master => Chef::Config[:xenserver][:pool_master],
          :xenserver_defaults    => Chef::Config[:xenserver][:defaults]
        )

        config[:server_name] ||= ask("Server Name? ".red)
        config[:run_list]    ||= ["recipe[scaffold]"]

          config[:scaffold] ||= {}
          config[:scaffold][:hostname]   ||= ask("Hostname? ".red) {|q| q.default = config[:server_name]; q.validate = /^[A-Za-z\d\-]+$/;}
          config[:scaffold][:fqdn]       ||= ask("FQDN? ".red) {|q| q.default = "#{config[:server_name]}.millicorp.com"; q.validate = /^.*.millicorp.com/}
          config[:scaffold][:ip_address] ||= ask("IP Address? ".red) {|q| q.validate = /^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$/}
          config[:scaffold][:netmask]    ||= ask("Netmask? ".red) {|q| q.default = "255.255.255.0"}
          config[:scaffold][:gateway]    ||= ask("Gateway? ".red) {|q| q.default = config[:scaffold][:ip_address].split('.')[0..2].push('1').join('.')}
          config[:scaffold][:net_device] ||= ask("Default Net Device? ".red) {|q| q.default = "eth0"}

          order    = {"scaffold" => config[:scaffold], "run_list" => config[:run_list]}
          filename = ["first-boot",'json'].join('.')
          puts "Writing configuration to file: #{h.color(filename, :bold)}"
          File.open("/usr/lib/ruby/gems/1.8/gems/chef-server-webui-0.9.8/public/#{filename}", 'w') {|f| f.write( order.to_json )}
          puts "-" * 20

        puts "Creating with the following defaults:"
        puts "#{h.color("Baseline", :cyan)}: #{Chef::Config[:xenserver][:defaults][:image]}"
        puts "#{h.color("Network", :cyan)} : #{Chef::Config[:xenserver][:defaults][:network]}"
        puts "Cloning from baseline image..."
        mac_address = xenserver.create_server(config[:server_name])

        print "Server starting up..."
        $stdout.sync = true

        loop do
          server = xenserver.get_vm(config[:server_name])
          print '.'
          if server[:power_state] == 'Running'
            break
          end
          sleep 5
        end

        puts "\nServer #{h.color("Online", :green)}"

      end
    end
  end
end