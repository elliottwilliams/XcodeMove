require 'optparse'

module XcodeMove
  class Parser
    @options = {
      git: system('git rev-parse')
    }

    @parser = OptionParser.new do |opts|
      opts.banner = 'Usage: xcmv src_file [...] dst_file'

      opts.on('--git=[true|false]', TrueClass, 'Use `git mv` (default: true if in a git repo)') do |git|
        @options[:git] = git
      end

      opts.on('-t[TARGETS]', '--targets=[TARGETS]', String,
              'Comma-separated list of targets to add moved files to (default: guess)') do |targets|
        @options[:targets] = targets.split(',')
      end

      opts.on('-h[HEADERS]', '--headers=[HEADERS]', %i[public project private],
              'Visibility level of moved header files (default: `public` for frameworks, `project` otherwise)') do |visibility|
        map = { public: HeaderVisibility::PUBLIC,
                project: HeaderVisibility::PROJECT,
                private: HeaderVisibility::PRIVATE }
        @options[:headers] = map[visibility]
      end

      opts.on('--help', 'This help message')

      opts.on('-v', '--version') do
        puts VERSION
        exit
      end
    end

    class << self
      attr_reader :options, :parser

      def run!(argv = ARGV)
        parser.parse!(argv)
        raise OptionParser::MissingArgument if argv.count < 2

        argv.map! { |a| Pathname.new(a) }

        if (dst = argv.pop).directory?
          argv.each { |src| XcodeMove.mv(src, dst, options) }
        else
          src = argv.pop
          raise InputError, "Error: moving more than one file to #{dst}\n" unless argv.empty?
          raise InputError, "Error: Not a directory\n" if src.directory? && dst.exist?

          XcodeMove.mv(src, dst, options)
        end
      rescue OptionParser::MissingArgument, OptionParser::InvalidArgument
        abort parser.help
      end
    end
  end
end
