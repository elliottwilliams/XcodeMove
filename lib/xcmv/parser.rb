# frozen_string_literal: true

require 'optparse'

module XcodeMove
  # Converts command-line arguments into a Parser::Options struct specifying
  # how to xcmv.
  class Parser
    Options = Struct.new(:srcs, :dst, :git, :targets, :headers)

    class << self
      def parse!(argv = ARGV)
        argv = argv.clone
        options = parsed_options(argv)
        options.git ||= system('git rev-parse', err: ::File::NULL)
        options.dst, options.srcs = paths_from(argv)

        check_missing_arguments(options)
        check_paths(options)
        options
      rescue OptionParser::MissingArgument, OptionParser::InvalidArgument
        abort parser.help
      end

      private

      def paths_from(argv)
        [
          argv.pop&.to_pathname,
          argv.map(&:to_pathname)
        ]
      end

      def check_missing_arguments(options)
        raise OptionParser::MissingArgument if options.dst.nil? || options.srcs.first.nil?
      end

      def check_paths(options)
        srcs = options.srcs
        dst = options.dst
        to_directory = dst.directory?

        raise InputError, "Error: moving more than one file to #{dst}\n" if (srcs.count > 1) && !to_directory
        raise InputError, "Error: Not a directory\n" if srcs.first.directory? && dst.exist? && !dst.directory?
      end

      def parsed_options(argv)
        options = Options.new
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
                  'Visibility level of moved header files (default: `public` ' \
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
