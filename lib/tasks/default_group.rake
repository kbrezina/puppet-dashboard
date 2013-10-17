namespace :defaultgroup do
  RAKE_ROOT = File.dirname(__FILE__)

  desc 'Ensure that the default group exists'
  task :ensure_default_group => :environment do
    lockfile = File.new("#{RAKE_ROOT}/default_group.lock", File::CREAT)
    if lockfile.flock(File::LOCK_NB | File::LOCK_EX)
      group = NodeGroup.find_by_name("default")
      group = NodeGroup.new(:name => "default") if group.nil?

      # Classes is empty here is it is a new group, otherwise it is the array of already existing classes
      classes = group.node_classes

      req_classes = ['pe_compliance', 'pe_accounts', 'pe_mcollective']
      begin
        req_classes.each do |name|
          nc = NodeClass.find_by_name(name)
          if nc.nil?
            nc = NodeClass.new(:name => name)
            nc.save
          end
          classes << nc unless classes.include?(nc)
        end
      end
      group.node_classes = classes
      group.save

      ENV['group'] = "default"
      Rake::Task['nodegroup:add_all_nodes'].invoke
      lockfile.flock(File::LOCK_UN)
    end
  end
end
