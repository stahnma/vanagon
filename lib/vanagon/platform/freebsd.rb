class Vanagon
  class Platform
    class FREEBSD < Vanagon::Platform
      # The specific bits used to generate a freebsd package for a given project
      #
      # @param project [Vanagon::Project] project to build a freebsd package of
      # @return [Array] list of commands required to build a freebsd package for the given project from a tarball
      def generate_package(project)
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        pkg_arch_opt = project.noarch ? "" : "-a#{@architecture}"
        ["mkdir -p output/#{target_dir}",
        "mkdir -p $(tempdir)/#{project.name}-#{project.version}",
        "cp -pr freebsd $(tempdir)/#{project.name}-#{project.version}",
        "gunzip -c #{project.name}-#{project.version}.tar.gz | '#{@tar}' -C '$(tempdir)/#{project.name}-#{project.version}' --strip-components 1 -xf -",
        "cp $(tempdir)/*.pkg ./output/#{target_dir}"]
      end

      # Method to generate the files required to build a freebsd package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_packaging_artifacts(workdir, name, binding)
        pkg_dir = File.join(workdir, "freebsd")
        FileUtils.mkdir_p(pkg_dir)

        File.open(File.join(pkg_dir, "manifest"), "w") { |f| f.puts("blank") }
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the freebsd package for this project
      def package_name(project)
        "#{project.name}_#{project.version}-#{project.release}#{@codename}_#{project.noarch ? 'all' : @architecture}.pkg"
      end

      # Get the expected output dir for the freebsd packages. This allows us to
      # use some standard tools to ship internally.
      #
      # @return [String] relative path to where freebsd packages should be staged
      def output_dir(target_repo = "")
        File.join("pkg", target_repo)
      end

      # Returns the string to add a target repo to the platforms' provisioning
      #
      # @param definition [URI] A URI to a pkg or list file
      # @return [String] The command to add the repo target to the system
      def add_repo_target(definition)
        if File.extname(definition.path) == '.pkg'
          # repo definition is an pkg (like puppetlabs-release)
          "curl -o local.pkg '#{definition}' && dpkg -i local.pkg; rm -f local.pkg"
        else
          reponame = "#{SecureRandom.hex}-#{File.basename(definition.path)}"
          reponame = "#{reponame}.list" if File.extname(reponame) != '.list'
          "curl -o '/etc/apt/sources.list.d/#{reponame}' '#{definition}'"
        end
      end

      # Returns the string to add a gpg key to the platforms' provisioning
      #
      # @param gpg_key [URI] A URI to the gpg key
      # @return [String] The command to add the gpg key to the system
      def add_gpg_key(gpg_key)
        gpgname = "#{SecureRandom.hex}-#{File.basename(gpg_key.path)}"
        gpgname = "#{gpgname}.gpg" if gpgname !~ /\.gpg$/
        "curl -o '/etc/apt/trusted.gpg.d/#{gpgname}' '#{gpg_key}'"
      end

      # Returns the commands to add a given repo target and optionally a gpg key to the build system
      #
      # @param definition [String] URI to the repo (.pkg or .list)
      # @param gpg_key [String, nil] URI to a gpg key for the repo
      def add_repository(definition, gpg_key = nil)
        # i.e., definition = http://builds.delivery.puppetlabs.net/puppet-agent/0.2.1/repo_configs/pkg/pl-puppet-agent-0.2.1-wheezy.list
        # parse the definition and gpg_key if set to ensure they are both valid URIs
        definition = URI.parse(definition)
        gpg_key = URI.parse(gpg_key) if gpg_key
        provisioning = ["apt-get -qq update && apt-get -qq install curl"]

        if definition.scheme =~ /^(http|ftp)/
          provisioning << add_repo_target(definition)
        end

        if gpg_key
          provisioning << add_gpg_key(gpg_key)
        end

        provisioning << "apt-get -qq update"
      end

      # Constructor. Sets up some defaults for the freebsd platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::FREEBSD] the pkg derived platform with the given name
      def initialize(name)
        @name = name
        @make = "/usr/local/bin/gmake"
        @tar = "tar"
        @num_cores = "/usr/bin/nproc"
        super(name)
      end
    end
  end
end
