module Pod
  class Command
    class Dependency < Command
      include Command::ProjectDirectory

      self.summary = 'Help you know your project dependecncies with HTML file.'

      self.description = <<-DESC
        Shows the project's dependency.
      DESC

      def self.arguments
        [
          CLAide::Argument.new('NAME', false)
        ].concat(super)
      end

      def initialize(argv)
        @name = argv.shift_argument
        @dependency_names = Array.new
        @dependencies_hash = Hash.new
        super
      end

      def validate!
        super
        puts @name
      end

      def run
        require 'yaml'
        require 'launchy'

        Launchy.open( "/Users/SFM/workspace/cocoapods-dependency/lib/cocoapods-dependency/front-end/dependency_graph.html")

        UI.title "Calculating dependencies" do
          dependencies ## hash
        end

        UI.title 'Dependencies' do
          dependencies.map { |dep|
            if dep.is_a? Hash
              dep_hash = dep.to_h
              key = remove_version(dep_hash.keys.first)
              if !is_subspec(key)
                @dependencies_hash.store(key, dep_hash[dep_hash.keys.first])
                @dependency_names << key
              end

            else
              if !is_subspec(dep)
                @dependencies_hash.store(remove_version(dep), dep)
                @dependency_names << remove_version(dep)
              end
            end
          }

          if @name
            UI.title "#{@name} Dependencies" do
              puts @dependencies_hash["#{@name}"]
            end
          end

          module_arr = Array.new
          kss_arr = Array.new
          second_party = Array.new
          third_party = Array.new

          @dependency_names.map { |dep|
            if dep =~ /^LPD.*?Module/
              module_arr << dep
            elsif dep =~ /^LPD/ && dep =~ /Kit|SDK|Service/
              kss_arr << dep
            elsif dep =~ /\||^ELM|^APF|^LPD/
              second_party << dep
            else
              third_party << dep
            end
          }

          UI.title 'First Level Dependencies' do
              puts module_arr
          end

          UI.title 'Second Level Dependencies' do
              puts kss_arr
          end

          UI.title 'Third Level Dependencies' do
              puts second_party
          end

          UI.title 'Other Level Dependencies' do
              puts third_party
          end
        end
      end

      def remove_version pod_name
          if pod_name.include? " "
            return pod_name.split(" ").first
          end
          pod_name
      end

      def get_pod_dependency pod_name
        return @dependencies_hash[pod_name]
      end

      def is_subspec pod_name
          if pod_name.include? "/"
            return true
          end
  	      return false
      end

      def dependencies
        @dependencies ||= begin
          lockfile = config.lockfile unless @ignore_lockfile || @podspec

          if !lockfile || @repo_update
            analyzer = Installer::Analyzer.new(
              sandbox,
              podfile,
              lockfile
            )

            specs = config.with_changes(skip_repo_update: !@repo_update) do
              analyzer.analyze(@repo_update || @podspec).specs_by_target.values.flatten(1)
            end

            lockfile = Lockfile.generate(podfile, specs, {})
          end

          lockfile.to_hash['PODS']
        end
      end

    end
  end
end
