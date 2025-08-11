namespace :assets do
  desc "Build CSS assets"
  task :build_css do
    system("npm run build:css") || raise("CSS build failed")
  end
end

# Hook into assets:precompile
Rake::Task["assets:precompile"].enhance(["assets:build_css"])