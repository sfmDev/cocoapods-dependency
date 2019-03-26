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

        @output_dependencies_hash = Hash.new
        @output_dependencies_hash["nodes"] = []
        @output_dependencies_hash["edges"] = []
        super
      end

      def validate!
        super
        puts @name
      end

      def run
        UI.title "Calculating dependencies" do
          dependencies
        end

        UI.title 'Dependencies' do
          dependencies.map { |dep|
            if dep.is_a? Hash
              dep_hash = dep.to_h
              key = remove_version(dep_hash.keys.first)
              @dependencies_hash.store(key, dep_hash[dep_hash.keys.first])
              @dependency_names << key
            else
              @dependencies_hash.store(remove_version(dep), dep)
              @dependency_names << remove_version(dep)
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
            temp_dep = get_pod_name(dep)
            if temp_dep =~ /^LPD.*?Module/
              module_arr << dep
            elsif temp_dep =~ /^LPD/ && temp_dep =~ /Kit|SDK|Service/
              kss_arr << dep
            elsif temp_dep =~ /\||^ELM|^APF|^LPD/
              second_party << dep
            else
              if !is_subspec(dep)
                third_party << dep
              end
            end
          }

          root_sourceId = get_project_name
          add_root(root_sourceId, module_arr.count)

          UI.title 'Other Level Dependencies' do
              puts third_party
              for i in 0..third_party.count-1
                pod_name = third_party[i]
                add_node(pod_name, get_pod_size(pod_name), i, 4, i % 2 == 0)
              end
          end

          UI.title 'Third Level Dependencies' do
              puts second_party
              for i in 0..second_party.count-1
                pod_name = second_party[i]
                add_node(second_party[i], get_pod_size(pod_name), i, 3, i % 2 == 0)
              end
          end

          UI.title 'Second Level Dependencies' do
              puts kss_arr
              for i in 0..kss_arr.count-1
                pod_name = kss_arr[i]
                add_node(kss_arr[i], get_pod_size(pod_name), i, 2, i % 2 == 0)
              end
          end

          UI.title 'First Level Dependencies' do
              puts module_arr
              for i in 0..module_arr.count-1
                pod_name = module_arr[i]
                add_node(module_arr[i], get_pod_size(pod_name), i, 1, i % 2 == 0)
                add_edge(root_sourceId, remove_version(module_arr[i]))
              end
          end

          @dependencies_hash.each { |key,value|
            if value.class == Array
               for i in 0..value.count - 1
                 pod = value[i]
                 if key != value[i]
                   if !is_subspec(remove_version(pod))
                     add_edge(key, remove_version(pod))
                   end
                 end
               end
            end
          }

          p `rm -rf pod_dependency.json`
          p `touch pod_dependency.json`
          File.open("./pod_dependency.json","w") do |f|
            dep_json = JSON @output_dependencies_hash
            f.write("index(" + dep_json + ")")

            require 'yaml'
            require 'launchy'
            p `wget https://raw.githubusercontent.com/sfmDev/cocoapods-dependency/master/lib/cocoapods-dependency/front-end/dependency_graph.html`
            Launchy.open("./dependency_graph.html")
          end
        end
      end

      def get_project_name
        path = `pwd`
        return path.split("/").last
      end

      def get_pod_size pod_name
        if  @dependencies_hash["#{pod_name}"].class == Array
          return 15
        else
          return 15
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

      def get_pod_name pod
        pod_name_subspec = remove_version(pod)
        if pod_name_subspec.include? "/"
          return pod_name_subspec.split("/").first
        end
        pod_name_subspec
      end

      def is_subspec pod_name
          if pod_name.include? "/"
            return true
          end
  	      return false
      end

      def add_root(pod_name, size)
          node = Hash.new
          node["color"] = "#4f19c7"
          node["label"] = pod_name
          node["attributes"] = {}
          node["y"] = -2000
          node["x"] = 0
          node["id"] = pod_name
          node["size"] = size
          @output_dependencies_hash["nodes"] << (node)
      end

      def get_level_color level
          if level == 0
            return "#F75855"
          elsif level == 1
            return "#EC944B"
          elsif level == 2
            return "#ACD543"
          elsif level == 3
            return "#45D5AA"
          elsif level == 4
            return "#EB1E0F"
          else
            return "#45D5AA"
          end
      end

      def add_node(pod_name, size, index, level, is_left)
          node = Hash.new
          node["color"] = get_level_color(level)
          node["label"] = pod_name
          node["attributes"] = {}
          node["y"] = -2000 + level * 2000
          if is_left
            node["x"] = 0 + (index + 1) * 150
          else
            node["x"] = 0 - index * 150
          end

          node["id"] = pod_name
          node["size"] = size
          @output_dependencies_hash["nodes"] << (node)
      end

      def add_edge(source_id, target_id)
          edge = Hash.new
          edge["sourceID"] = source_id
          edge["targetID"] = target_id
          edge["attributes"] = {}
          edge["size"] = 1
          @output_dependencies_hash["edges"] << (edge)
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
