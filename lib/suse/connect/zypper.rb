require 'rexml/document'
require 'debugger'
require 'suse/connect/rexml_refinement'

module SUSE
  module Connect
    # Implements zypper interaction
    class Zypper
      using RexmlRefinement

      class << self
        ##
        # Returns an array of all installed products, in which every product is
        # presented as a hash.
        def installed_products
          zypper_out = `zypper --no-refresh --quiet --xmlout --non-interactive products -i`
          xml_doc = REXML::Document.new(zypper_out, :compress_whitespace => [])
          # Not unary because of https://bugs.ruby-lang.org/issues/9451
          xml_doc.root.elements['product-list'].elements.map {|x| x.to_hash }
        end

        def base_product
          installed_products.select {|product| product[:is_base] == '1' }.first
        end

        def add_service(service_name, service_url)
          zypper_args = "--quiet --non-interactive addservice #{service_url} '#{service_name}'"
          call(zypper_args)
        end

        def remove_service(service_name)
          zypper_args = "--quiet --non-interactive removeservice '#{service_name}'"
          call(zypper_args)
        end

        def refresh
          call('refresh')
        end

        def enable_service_repository(service_name, repository)
          zypper_args = "--quiet modifyservice --ar-to-enable '#{service_name}:#{repository}' '#{service_name}'"
          call(zypper_args)
        end

        def disable_repository_autorefresh(service_name, repository)
          zypper_args = "--quiet modifyrepo --no-refresh '#{service_name}:#{repository}'"
          call(zypper_args)
        end

        # TODO: introduce Source class
        def write_source_credentials(source_name)
          login, password = System.credentials
          write_credentials_file(
              :login => login,
              :password => password,
              :filename => source_name
          )
        end

        def write_base_credentials(login, password)
          write_credentials_file(
              :login => login,
              :password => password,
              :filename => CREDENTIALS_NAME
          )
        end

        private

        # TODO: move to toolkit module and include later ?
        def write_credentials_file(login:, password:, filename:)
          credentials_dir = ZYPPER_CREDENTIALS_DIR
          Dir.mkdir(credentials_dir) unless Dir.exists?(credentials_dir)
          credentials_file = File.join(credentials_dir, filename)

          begin
            file = File.open(credentials_file, 'w')
            file.puts("username=#{sccized_login(login)}")
            file.puts("password=#{password}")
          rescue IOError => e
            Logger.error(e.message)
          ensure
            file.close
          end
        end

        def sccized_login(login)
          login.start_with?('SCC_') ? login : "SCC_#{login}"
        end

        def call(args)
          command = "zypper #{args}"
          Logger.error "command `#{command}` failed" unless system(command)
        end
      end
    end
  end
end