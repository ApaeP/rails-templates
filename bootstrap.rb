run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# Gemfile
########################################
inject_into_file "Gemfile", before: "group :development, :test do" do
  <<~RUBY
    gem "bootstrap", "~> 5.2"
    gem "autoprefixer-rails"
    gem "font-awesome-sass", "~> 6.1"
    # gem "font-awesome-sass", "~> 6.4.2"
    gem "simple_form", github: "heartcombo/simple_form"
    gem "sassc-rails"
    gem "view_component"
  RUBY
end

inject_into_file "Gemfile", after: "group :development, :test do" do
  "\n  gem \"dotenv-rails\"\n  gem \"annotate\"\n  gem \"pry-byebug\"\n  gem \"pry-rails\"\n"
end

inject_into_file "Gemfile", after: "group :development do" do
  "\n  gem \"better_errors\"\n  gem \"binding_of_caller\""
end

# Assets
########################################
run "rm -rf app/assets/stylesheets"
run "rm -rf vendor"
run "curl -L https://github.com/ApaeP/rails-stylesheets/archive/master.zip > stylesheets.zip"
run "unzip stylesheets.zip -d app/assets && rm -f stylesheets.zip"
run "mv app/assets/rails-stylesheets-master app/assets/stylesheets"

# Layout
########################################

gsub_file(
  "app/views/layouts/application.html.erb",
  '<meta name="viewport" content="width=device-width,initial-scale=1">',
  '<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">'
)

# README
########################################
markdown_file_content = <<~MARKDOWN
  Ok
MARKDOWN
file "README.md", markdown_file_content, force: true

# Generators
########################################
generators = <<~RUBY
  config.generators do |generate|
    generate.assets false
    generate.helper false
    generate.test_framework :test_unit, fixture: false
  end
RUBY

environment generators

# General Config
########################################
general_config = <<~RUBY
  config.action_controller.raise_on_missing_callback_actions = false if Rails.version >= "7.1.0"
RUBY

environment general_config

########################################
# After bundle
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command "db:drop db:create db:migrate"
  generate("simple_form:install", "--bootstrap")
  generate(:controller, "pages", "home", "--skip-routes", "--no-test-framework")
  generate(:component, "Example", 'title')

  # Routes
  ########################################
  route 'root to: "pages#home"'

  # Gitignore
  ########################################
  append_file ".gitignore", <<~TXT

    # Ignore .env file containing credentials.
    .env*

    # Ignore Mac and Linux file system files
    *.swp
    .DS_Store
  TXT

  # Bootstrap & Popper
  ########################################
  append_file "config/importmap.rb", <<~RUBY
    pin "bootstrap", to: "bootstrap.min.js", preload: true
    pin "@popperjs/core", to: "popper.js", preload: true
  RUBY

  append_file "config/initializers/assets.rb", <<~RUBY
    Rails.application.config.assets.precompile += %w(bootstrap.min.js popper.js)
  RUBY

  append_file "app/javascript/application.js", <<~JS
    import "@popperjs/core"
    import "bootstrap"
  JS

  append_file "app/assets/config/manifest.js", <<~JS
    //= link popper.js
    //= link bootstrap.min.js
  JS

  # Heroku
  run "bundle lock --add-platform x86_64-linux"

  # Dotenv
  ########################################
  run "touch '.env'"

  # Rubocop
  ########################################
  run "curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml"

  # Git
  ########################################
  git :init
  git add: "."
  git commit: "-m 'Init app with minimal template'"
end
