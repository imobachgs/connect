source 'https://rubygems.org'

ruby '2.1.0'

group :test, :development do
  gem 'debugger'
  gem 'yard'
end

group :development do
  gem 'redcarpet'
end

group :test do
  gem 'rubocop', '~> 0.18.1', :require => false
  gem 'coveralls', :require => false
  gem 'rspec', '~> 2.14'
  gem 'webmock', '~> 1.15'
  gem 'aruba'
end

gemspec