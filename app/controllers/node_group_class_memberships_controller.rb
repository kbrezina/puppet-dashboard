class NodeGroupClassMembershipsController < InheritedResources::Base
  respond_to :html, :json
  before_filter :raise_unless_using_external_node_classification
  before_filter :raise_if_enable_read_only_mode, :only => [:new, :edit, :create, :update, :destroy]

  include SearchableIndex
  include ConflictAnalyzer

  def update
    ActiveRecord::Base.transaction do
      old_conflicts = get_all_current_conflicts

      update! do |success, failure|
        success.html {
  
          membership = NodeGroupClassMembership.find_by_node_group_id_and_node_class_id(
                                                  @node_group_class_membership.node_group_id, @node_group_class_membership.node_class_id)
  
          @node_group_class_membership = membership
  
          @conflict_message
          new_conflicts = get_new_conflicts(old_conflicts)
          if new_conflicts.length > 0
            @conflict_message = "You have introduced new conflicts!\\n"
            new_conflicts.keys.each do |group_name|
              @conflict_message = @conflict_message + "\\nGroup: " + group_name
              conflicts = new_conflicts[group_name]
              if conflicts.global_conflicts.length > 0
                @conflict_message += "\\n  Global conflicts:\\n"
                conflict.global_conflicts.each do |conflict|
                  @conflict_message += "    " + conflict.name + " (" + conflict.value + "): " +
                    conflict.sources.map{ |source| source.name}.join(",")
                end
                @conflict_message += "\\n"
              end
              if conflicts.class_conflicts.length > 0
                @conflict_message += "\\n  Class conflicts:\\n"
                conflicts.class_conflicts.keys.each do |node_class|
                  @conflict_message += "    " + node_class.name + ": "
                  conflicts.class_conflicts[node_class].each do |conflict|
                    @conflict_message += conflict.name + " (" + conflict.value + ") - " +
                      conflict.sources.map{ |source| source.name}.join(",")
                  end
                end
                @conflict_message += "\\n"
              end
            end

            render :edit
            raise ActiveRecord::Rollback
          else
            redirect_to @node_group_class_membership
          end
        }
      end
    end
  end
end
