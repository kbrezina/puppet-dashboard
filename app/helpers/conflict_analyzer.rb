require 'ostruct'
#require 'app/models/node_group'

module ConflictAnalyzer
  def get_all_current_conflicts
    conflicts = {}

    NodeGroup.find(:all).each do |nodegroup|
      nodegroup.class_conflicts
      conflicts[nodegroup.name] = OpenStruct.new :global_conflicts => nodegroup.global_conflicts.nil? ? [] : nodegroup.global_conflicts,
        :class_conflicts => nodegroup.class_conflicts.nil? ? {} : nodegroup.class_conflicts
    end
    
    conflicts
  end

  def get_new_conflicts(old_conflicts)
    current_conflicts = get_all_current_conflicts
    new_conflicts = {}
    current_conflicts.keys.each do |group_name|
      if !old_conflicts.keys.member?(group_name)
        new_conflicts[group_name] = current_conflicts[group_name]
      else
        new_global_conflicts = current_conflicts[group_name].global_conflicts.select { |current|
          existed = false
          old_conflicts[group_name].global_conflicts.each do |old|
            if old.name == current.name && old.sources = current.sources
              existed = true
              break
            end
          end
          
          !existed
        }

        old_class_conflicts = old_conflicts[group_name].class_conflicts;
        current_class_conflicts = current_conflicts[group_name].class_conflicts;
        new_class_conflicts = {}
        current_class_conflicts.keys.each do |class_name|
          if !(old_class_conflicts.include?(class_name) &&
              old_class_conflicts[class_name] == current_class_conflicts[class_name])
             new_class_conflicts[class_name] = current_class_conflicts[class_name]
          end
        end

        if new_global_conflicts.length + new_class_conflicts.length > 0
          new_conflicts[group_name] = OpenStruct.new :global_conflicts => new_global_conflicts, :class_conflicts => new_class_conflicts
        end
      end
    end

    new_conflicts
  end
end