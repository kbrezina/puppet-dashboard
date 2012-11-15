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

          unless(force_update?)
            membership = NodeGroupClassMembership.find_by_node_group_id_and_node_class_id(
                                                    @node_group_class_membership.node_group_id, @node_group_class_membership.node_class_id)

            @node_group_class_membership = membership

            new_conflicts = get_new_conflicts(old_conflicts)
            if new_conflicts.length > 0
              conflict_message = "You have introduced new conflicts!\\n"
              new_conflicts.keys.each do |group_name|
                conflict_message = conflict_message + "\\nGroup: " + group_name
                conflicts = new_conflicts[group_name]
                if conflicts.global_conflicts.length > 0
                  conflict_message += "\\n  Global conflicts:\\n"
                  conflict.global_conflicts.each do |conflict|
                    conflict_message += "    " + conflict.name + " (" + conflict.value + "): " +
                      conflict.sources.map{ |source| source.name}.join(",")
                  end
                  conflict_message += "\\n"
                end
                if conflicts.class_conflicts.length > 0
                  conflict_message += "\\n  Class conflicts:\\n"
                  conflicts.class_conflicts.keys.each do |node_class|
                    conflict_message += "    " + node_class.name + ": "
                    conflicts.class_conflicts[node_class].each do |conflict|
                      conflict_message += conflict.name + " (" + conflict.value + ") - " +
                        conflict.sources.map{ |source| source.name}.join(",")
                    end
                  end
                  conflict_message += "\\n"
                end
              end

              html = render_to_string(:template => "shared/_confirm",
                                      :layout => false,
                                      :locals => { :message => conflict_message, :confirm_label => "Update", :on_confirm_clicked_script => "event.preventDefault(); $('force_update').value = 'true'; $('submit_button').click();" })
              render :json => { :status => "ok", :valid => "false", :confirm_html => html }, :content_type => 'application/json'
              raise ActiveRecord::Rollback
            end
          end

          render :json => { :status => "ok", :valid => "true", :redirect_to => url_for(@node_group_class_membership) }, :content_type => 'application/json'
        };

        failure.html {
          html = render_to_string(:template => "shared/_error",
                                  :layout => false,
                                  :locals => { :object_name => 'node_group_class_membership', :object => @node_group_class_membership })
          render :json => { :status => "error", :error_html => html }, :content_type => 'application/json'
        }
      end
    end
  end

  private

  def force_update?
    !params["force_update"].nil? && params["force_update"] == "true"
  end
end
