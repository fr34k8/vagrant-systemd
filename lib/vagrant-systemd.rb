require "vagrant"

module VagrantPlugins
  module GuestSystemd
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/os-release")
      end
    end

    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          machine.communicate.tap do |comm|
            # Only do this if the hostname is not already set
            if !comm.test("sudo hostname | grep '#{name}'")
              comm.sudo("hostnamectl set-hostname #{name}")
              comm.sudo("sed -i 's@^\\(127[.]0[.]0[.]1[[:space:]]\\+\\)@\\1#{name} @' /etc/hosts")
            end
          end
        end
      end

      class ConfigureNetworks
        def self.configure_networks(machine, networks)
          networks.each do |network|
            entry = TemplateRenderer.render("guests/arch/network_#{network[:type]}",
                                            :options => network)

            temp = Tempfile.new("vagrant")
            temp.binmode
            temp.write(entry)
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
