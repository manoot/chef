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

require 'chef/knife'
require 'json'
require 'tempfile'

class Chef
  class Knife
    class XenServerList < Knife
      
      banner "knife xen server list (options)"
      
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
        
        server_name = @name_args[0]
        
        xenserver = Fog::Xenserver.new(
          :xenserver_username    => Chef::Config[:xenserver][:username],
          :xenserver_password    => Chef::Config[:xenserver][:password],
          :xenserver_pool_master => Chef::Config[:xenserver][:pool_master],
          :xenserver_defaults    => Chef::Config[:xenserver][:defaults]
        )
        
        $stdout.sync = true
        
        server_list = [ h.color('MAC', :bold), h.color('Name', :bold) ]
        xenserver.servers.all.each do |server|
          server_list << server.mac_address
          server_list << server.name_label.to_s
        end
        puts h.list(server_list, :columns_across, 2)
        
      end
    end
  end
end


