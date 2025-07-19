Gem::Specification.new do |s|
  s.name = "hubbado-trailblazer"
  s.version = "1.2.0"
  s.summary = "Enhanced Trailblazer operation utilities for Ruby applications with improved error handling, operation execution patterns, and ActiveRecord integration."

  s.authors = ["Hubbado Devs"]
  s.email = ["devs@hubbado.com"]
  s.homepage = 'https://github.com/hubbado/hubbado-trailblazer'

  s.metadata["github_repo"] = s.homepage
  s.metadata["homepage_uri"] = s.homepage
  s.metadata["changelog_uri"] = "#{s.homepage}/blob/master/CHANGELOG.md"

  s.require_paths = ["lib"]
  s.files = Dir.glob(%w[
    lib/**/*.rb
    *.gemspec
    LICENSE*
    README*
    CHANGELOG*
  ])
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = ">= 3.2"

  s.add_dependency "evt-template_method"
  s.add_dependency "hubbado-log"
  s.add_dependency "trailblazer-operation"

  s.add_development_dependency "activerecord"
  s.add_development_dependency "debug"
  s.add_development_dependency "dry-validation"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "hubbado-style"
  s.add_development_dependency "reform"
  s.add_development_dependency "test_bench"
  s.add_development_dependency "trailblazer-macro"
  s.add_development_dependency "trailblazer-macro-contract"
end
