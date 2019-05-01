require 'optparse'

module XcodeMove
  class Parser
    Options = Struct.new(:srcs, :dst, :git, :targets, :headers)

    def self.parse!(argv = ARGV)
      argv = argv.clone
      options = Options.new
      options.git = system('git rev-parse', err: ::File::NULL)
      parse_flags!(options, argv)
      raise OptionParser::MissingArgument if argv.count < 2

      argv.map! { |a| Pathname.new(a) }

      if (options.dst = argv.pop).directory?
        options.srcs = argv
      else
        raise InputError, "Error: moving more than one file to #{options.dst}\n" unless argv.count == 1
        raise InputError, "Error: Not a directory\n" if argv.first.directory? && options.dst.exist?
      end
      options.srcs = argv
      options
    rescue OptionParser::MissingArgument, OptionParser::InvalidArgument
      abort parser.help
    end

    class << self
      private
      def parse_flags!(options, argv)
        OptionParser.new do |opts|
          opts.banner = 'Usage: xcmv src_file [...] dst_file'

          opts.on('--git=[true|false]', TrueClass, 'Use `git mv` (default: true if in a git repo)') do |git|
            options.git = git
          end

          opts.on('-t[TARGETS]', '--targets=[TARGETS]', String,
                  'Comma-separated list of targets to add moved files to (default: guess)') do |targets|
            options.targets = targets.split(',')
          end

          opts.on('-h[HEADERS]', '--headers=[HEADERS]', %i[public project private],
                  'Visibility level of moved header files (default: `public` '
                  'for frameworks, `project` otherwise)') do |visibility|
            map = { public: HeaderVisibility::PUBLIC,
                    project: HeaderVisibility::PROJECT,
                    private: HeaderVisibility::PRIVATE }
            options.headers = map[visibility]
          end

          opts.on('--help', 'This help message')

          opts.on('-v', '--version') do
            puts VERSION
            exit
          end
        end.parse!(argv)
        options
      end
    end
  end
end
