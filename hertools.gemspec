require_relative 'lib/hertools/version'

Gem::Specification.new do |spec|
  spec.name          = "hertools"
  spec.version       = Hertools::VERSION
  spec.authors       = ["WuDi"]
  spec.email         = ["wudlvq@qq.com"]

  spec.summary       = %q{A tool box made for her.}
  spec.description   = %q{A tool box made for her. Provides more and more tools, like the WebsiteParser and so on.}
  spec.homepage      = "https://github.com/Amberwudi/hertools"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.add_dependency 'httparty', '~> 0.18', '>= 0.18.1'
  spec.add_dependency 'nokogiri', '~> 1.10', '>= 1.10.10'
  spec.add_dependency 'htmlentities', '~> 4.3', '>= 4.3.4'

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Amberwudi/hertools"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
