# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{periodic}
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chris Kalafarski"]
  s.date = %q{2009-03-16}
  s.description = %q{TODO}
  s.email = %q{chris@farski.com}
  s.files = ["README.rdoc", "VERSION.yml", "lib/periodic", "lib/periodic/duration.rb", "lib/periodic/parser.rb", "lib/periodic.rb", "test/parser_test.rb", "test/periodic_test.rb", "test/printer_test.rb", "test/test_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/farski/periodic}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{TODO}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
