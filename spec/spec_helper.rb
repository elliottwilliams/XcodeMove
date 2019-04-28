RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

RSpec.shared_context 'in project directory' do
  around do |ex|
    Dir.mktmpdir do |dir|
      dir = Pathname.new(dir)
      (dir / 'a').mkdir
      (dir / 'a/a.swift').write ''
      (dir / 'a/b.swift').write ''
      (dir / 'b').mkdir
      (dir / 'b/b.swift').write ''
      (dir / 'main.swift').write ''
      Dir.chdir(dir) { ex.run }
    end
  end
end
