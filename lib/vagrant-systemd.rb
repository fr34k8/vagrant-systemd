require "tempfile"
require "vagrant"

module VagrantPlugins
  module GuestSystemd
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("systemctl") and
        machine.communicate.test("netctl")
      end
    end

    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          name = name.split('.')
          hostname = name.shift
          domain = name.empty? ? "local" : name.join('.')

          machine.communicate.tap do |comm|
            # Only do this if the hostname is not already set
            if !comm.test("sudo hostname | grep '#{hostname}'")
              comm.sudo("hostnamectl set-hostname #{hostname}")
              comm.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{hostname}.#{domain} #{hostname} @' /etc/hosts")
            end
          end
        end
      end

      class ConfigureNetworks
        def self.configure_networks(machine, networks)
          networks.each do |network|
            template_path = File.expand_path("../../templates/network_#{network[:type]}.erb", __FILE__)
            template = File.read(template_path)

            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(Erubis::Eruby.new(template, :trim => true).result(binding))
            temp.close

            machine.communicate.upload(temp.path, "/tmp/vagrant_network")
            machine.communicate.sudo("ln -sf /dev/null /etc/udev/rules.d/80-net-name-slot.rules")
            machine.communicate.sudo("mv /tmp/vagrant_network /etc/netctl/eth#{network[:interface]}")
            machine.communicate.sudo("netctl start eth#{network[:interface]}")
          end
        end
      end
    end

    class Plugin < Vagrant.plugin("2")
      name "Systemd based guest"
      description "Systemd based guest support."

      guest("systemd", "linux") do
        Guest
      end

      guest_capability("systemd", "change_host_name") do
        Cap::ChangeHostName
      end

      guest_capability("systemd", "configure_networks") do
        Cap::ConfigureNetworks
      end
    end
  end
end
