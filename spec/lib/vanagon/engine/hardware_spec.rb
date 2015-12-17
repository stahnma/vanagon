require 'vanagon/engine/hardware'
require 'logger'

# Haus, I added this, cause it prevented errors.
@@logger = Logger.new('/dev/null')

describe 'Vanagon::Engine::Hardware' do

  # Haus here's where I started. And I'm a little lost.
let (:lock_manager) { double(Vanagon::Driver::Hardware::LockManager) }


  let (:platform_without_build_hosts) {
    plat = Vanagon::Platform::DSL.new('aix-7.1-ppc')
    plat.instance_eval("platform 'aix-7.1-ppc' do |plat|
                    end")
    plat._platform
  }

  let (:platform) {
    plat = Vanagon::Platform::DSL.new('aix-6.1-ppc')
    plat.instance_eval("platform 'aix-6.1-ppc' do |plat|
                      plat.build_host 'abcd'
                    end")
    plat._platform
  }

  describe '#select_target' do
#    it 'raises an error without a target' do
#      base = Vanagon::Engine::Hardware.new(platform)
#      expect { base.select_target }.to raise_error(Vanagon::Error)
#    end

    it 'returns a target if one is set' do
      base = Vanagon::Engine::Hardware.new(platform)
      puts base.select_target
      expect(base.select_target).to eq('abcd')
    end
  end

  describe '#validate_platform' do
    it 'raises an error if the platform is missing a required attribute' do
      expect{ Vanagon::Engine::Hardware.new(platform_without_build_hosts).validate_platform }.to raise_error(Vanagon::Error)
    end

    it 'returns true if the platform has the required attributes' do
      expect(Vanagon::Engine::Hardware.new(platform).validate_platform).to be(true)
    end
  end
end
