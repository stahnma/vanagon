require 'vanagon/utilities'
include Vanagon::Utilities

class Vanagon
  class Platform
    class TAR < Vanagon::Platform
      # The specific bits used to generate an tar package for a given project
      #
      # @param project [Vanagon::Project] project to build a tar package of
      # @return [Array] list of commands required to build a tar package for the given project from a tarball
      def generate_package(project)
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        [ "mkdir -p output/#{target_dir}",
          "cp #{project.name}-#{project.version}.tar.gz ./output/#{target_dir}"
        ]
        end

      # Method to generate the files required to build an tar package for the project
      #
      # @param workdir [String] working directory to stage the evaluated templates in
      # @param name [String] name of the project
      # @param binding [Binding] binding to use in evaluating the packaging templates
      def generate_packaging_artifacts(workdir, name, binding)
      end

      # Method to derive the package name for the project
      #
      # @param project [Vanagon::Project] project to name
      # @return [String] name of the tar package for this project
      def package_name(project)
        "#{project.name}-#{project.version}-#{project.release}.#{project.noarch ? 'noarch' : @architecture}.tar.gz"
      end

      # Get the expected output dir for the tar packages. This allows us to
      # use some standard tools to ship internally.
      #
      # @return [String] relative path to where tar packages should be staged
      def output_dir(target_repo = "products")
        File.join(@os_name, @os_version, target_repo, @architecture)
      end

      # Constructor. Sets up some defaults for the tar platform and calls the parent constructor
      #
      # @param name [String] name of the platform
      # @return [Vanagon::Platform::TAR] the tar derived platform with the given name
      def initialize(name)
        @name = name
        @make ||= "/usr/bin/make"
        @tar ||= "tar"
        @patch ||= "/usr/bin/patch"
        @num_cores ||= "/bin/grep -c 'processor' /proc/cpuinfo"
        super(name)
      end
    end
  end
end
