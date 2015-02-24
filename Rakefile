require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

Rake::TestTask.new do |t|
  t.name = :fastqc
  t.libs << 'test'
  t.test_files = ['test/test_fastqc.rb']
end

Rake::TestTask.new do |t|
  t.name = :rice
  t.libs << 'test'
  t.test_files = ['test/test_rice.rb']
end

desc "Run tests"
task :default => :test
