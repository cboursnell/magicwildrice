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

Rake::TestTask.new do |t|
  t.name = :synteny
  t.libs << 'test'
  t.test_files = ['test/test_synteny.rb']
end

Rake::TestTask.new do |t|
  t.name = :tophat
  t.libs << 'test'
  t.test_files = ['test/test_tophat.rb']
end

Rake::TestTask.new do |t|
  t.name = :cross
  t.libs << 'test'
  t.test_files = ['test/test_crossing.rb']
end

Rake::TestTask.new do |t|
  t.name = :assembly
  t.libs << 'test'
  t.test_files = ['test/test_assembly.rb']
end

Rake::TestTask.new do |t|
  t.name = :soap
  t.libs << 'test'
  t.test_files = ['test/test_soap.rb']
end


desc "Run tests"
task :default => :test
