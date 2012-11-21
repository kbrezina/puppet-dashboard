require 'ostruct'
#require 'app/models/node_group'

module ConflictAnalyzer
  def get_all_current_conflicts
    conflicts = {}

    NodeGroup.find(:all).each do |nodegroup|
      global_conflicts = nodegroup.global_conflicts.nil? ? [] : nodegroup.global_conflicts
      class_conflicts = nodegroup.class_conflicts.nil? ? {} : nodegroup.class_conflicts

      if global_conflicts.length > 0 || class_conflicts.length > 0
        conflicts[nodegroup.name] = {
          :global_conflicts => global_conflicts,
          :class_conflicts => class_conflicts
        }
      end
    end

    conflicts
  end

  def get_new_conflicts_message(old_conflicts)
    new_conflicts = get_new_conflicts(old_conflicts)
    if new_conflicts.length > 0
      conflict_message = "You have introduced new conflicts!\\n"
      new_conflicts.keys.each do |group_name|
        conflict_message = conflict_message + "\\nGroup: " + group_name
        conflicts = new_conflicts[group_name]
        if conflicts[:global_conflicts].length > 0
          conflict_message += "\\n  Global conflicts:\\n"
          conflict[:global_conflicts].each do |conflict|
            conflict_message += "    " + conflict[:name] + " (" + conflict[:value] + "): " +
              conflict[:sources].map{ |source| source.name}.join(",")
          end
          conflict_message += "\\n"
        end
        if conflicts[:class_conflicts].length > 0
          conflict_message += "\\n  Class conflicts:\\n"
          conflicts[:class_conflicts].keys.each do |node_class|
            conflict_message += "    " + node_class.name + ": "
            conflicts[:class_conflicts][node_class].each do |conflict|
              conflict_message += conflict[:name] + " (" + conflict[:value] + ") - " +
                conflict[:sources].map{ |source| source.name}.join(",")
            end
          end
          conflict_message += "\\n"
        end
      end
    else
      conflict_message = nil;
    end

    conflict_message;
  end

  def get_new_conflicts(old_conflicts)
    current_conflicts = get_all_current_conflicts
    new_conflicts = {}
    current_conflicts.keys.each do |group_name|
      if !old_conflicts.keys.member?(group_name)
        new_conflicts[group_name] = current_conflicts[group_name]
      else
        new_global_conflicts = current_conflicts[group_name][:global_conflicts].select { |current|
          existed = false
          old_conflicts[group_name][:global_conflicts].each do |old|
            if old[:name] == current[:name] && old[:sources] = current[:sources]
              existed = true
              break
            end
          end

          !existed
        }

        old_class_conflicts = old_conflicts[group_name][:class_conflicts];
        current_class_conflicts = current_conflicts[group_name][:class_conflicts];
        new_class_conflicts = {}
        current_class_conflicts.keys.each do |clazz|
          if !(old_class_conflicts.include?(clazz))
            new_class_conflicts[clazz] = current_class_conflicts[clazz]
          else
            new_class_conflicts[clazz] = current_class_conflicts[clazz].select { |current|
              existed = false
              old_class_conflicts[clazz].each do |old|
                if old[:name] == current[:name] && old[:sources] = current[:sources]
                  existed = true
                  break
                end
              end

              !existed
            }
          end
          if new_class_conflicts[clazz].length == 0
            new_class_conflicts.delete(clazz)
          end
        end

        if new_global_conflicts.length + new_class_conflicts.length > 0
          new_conflicts[group_name] = { :global_conflicts => new_global_conflicts, :class_conflicts => new_class_conflicts }
        end
      end
    end

    new_conflicts
  end
end