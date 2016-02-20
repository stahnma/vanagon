require 'vanagon/engine/base'

class Vanagon
  class Engine
    class Docker < Base
      # Both the docker_image and the docker command itself are required for
      # the docker engine to work
      def initialize(platform, target = nil)
        @docker_cmd = Vanagon::Utilities.find_program_on_path('docker')
        @name = 'docker'
        super
        @required_attributes << "docker_image"
      end

      def validate_platform
      end

      # This method is used to obtain a vm to build upon using
      # a docker container.
      # @raise [Vanagon::Error] if a target cannot be obtained
      def select_target
        suffix = (0...10).map { ('a'..'z').to_a[rand(26)] }.join
        Vanagon::Utilities.ex("#{@docker_cmd} run -d --name #{@platform.docker_image}-builder-#{suffix} -p #{@platform.ssh_port}:22 #{@platform.docker_image}")
        #Vanagon::Utilities.ex("#{@docker_cmd} run -d --name #{@platform.docker_image}-builder-#{suffix} #{@platform.docker_image}")
#       @platform.ssh_port = system("#{docker_cmd} docker inspect -f '{{json .NetworkSettings.Ports}}' #{@platform.docker_image} | awk -F: '{print $NF}' | cut -d\" -f2")
        @target = 'localhost'

        # Wait for ssh to come up in the container
        Vanagon::Utilities.retry_with_timeout do
          Vanagon::Utilities.remote_ssh_command("#{@target_user}@#{@target}", 'exit', @platform.ssh_port)
        end
      rescue => e
        raise Vanagon::Error.wrap(e, "Something went wrong getting a target vm to build on using docker. Ssh was not up in the container after 5 seconds.")
      end

      # This method is used to tell the vmpooler to delete the instance of the
      # vm that was being used so the pool can be replenished.
      def teardown
        Vanagon::Utilities.ex("#{@docker_cmd} stop #{@platform.docker_image}-builder")
        Vanagon::Utilities.ex("#{@docker_cmd} rm #{@platform.docker_image}-builder")
      rescue Vanagon::Error => e
        warn "There was a problem tearing down the docker container #{@platform.docker_image}-builder (#{e.message})."
      end
    end
  end
end

