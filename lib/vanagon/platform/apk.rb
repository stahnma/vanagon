class Vanagon
  class Platform
    class APK < Vanagon::Platform
      # The specific bits used to generate a apk package for a given project
      #
      # @param project [Vanagon::Project] project to build a apk package of
      # @return [Array] list of commands required to build a apk package for the given project from a tarball
      def generate_package(project)
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        ["mkdir -p output/#{target_dir}",
        "mkdir -p $(tempdir)/#{project.name}-#{project.version}",
        "gunzip -c #{project.name}-#{project.version}.tar.gz | '#{@tar}' -C '$(tempdir)/#{project.name}-#{project.version}' --strip-components 1 -xf -",
        "echo 'insert apk build steps here, I think'",
        "cp $(tempdir)/*.apk ./output/#{target_dir}"]
      end

      # Method to generate the files required to build an alpine package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_packaging_artifacts(workdir, name, binding)
        apk_dir = File.join(workdir, "apk")
        FileUtils.mkdir_p(apk_dir)

        # Lots of templates here
        ["APKBUILD", "pre-install", "pre-upgrade", "pre-deinstall", "post-install", "post-upgrade", "post-deinstall"].each do |apk_file|
          erb_file(File.join(VANAGON_ROOT, "resources/apk/#{apk_file}.erb"), File.join(apk, apk_file), false, { :binding => binding })
        end
        # Rename the template files to have hte proper prefix of $pkgname here
        # FIXME

      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the apk package for this project
      def package_name(project)
        "#{project.name}-#{project.version}-r#{project.release}.apk"
      end

      # Get the expected output dir for the alpine packages. This allows us to
      # use some standard tools to ship internally.
      #
      # @return [String] relative path to where alpine packages should be staged
      def output_dir(target_repo = "")
        File.join("apk", @arch, target_repo)
      end

      # Returns the string to add a target repo to the platforms' provisioning
      #
      # @param definition [URI] A URI to a apk or list file
      # @return [String] The command to add the repo target to the system
      def add_repo_target(definition)
        if File.extname(definition.path) == '.apk'
          # repo definition is an apk (like puppetlabs-release)
          "curl -o local.deb '#{definition}' && dpkg -i local.deb; rm -f local.deb"
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
      # @param definition [String] URI to the repo (.deb or .list)
      # @param gpg_key [String, nil] URI to a gpg key for the repo
      def add_repository(definition, gpg_key = nil)
        # i.e., definition = http://builds.delivery.puppetlabs.net/puppet-agent/0.2.1/repo_configs/deb/pl-puppet-agent-0.2.1-wheezy.list
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

      # Constructor. Sets up some defaults for the alpine platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::APK] the apk derived platform with the given name
      def initialize(name)
        @name = name
        @make = "make"
        @tar = "tar"
        @patch = "patch"
        @num_cores = "grep processor /proc/cpuinfo |wc -l"
        super(name)
      end
    end
  end
end
