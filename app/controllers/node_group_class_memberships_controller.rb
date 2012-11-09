class NodeGroupClassMembershipsController < InheritedResources::Base
  respond_to :html, :json
  before_filter :raise_unless_using_external_node_classification
  before_filter :raise_if_enable_read_only_mode, :only => [:new, :edit, :create, :update, :destroy]

  include SearchableIndex

  def update
    update! do |success, failure|
      success.html {

        membership = NodeGroupClassMembership.find_by_node_group_id_and_node_class_id(
                                                @node_group_class_membership.node_group_id, @node_group_class_membership.node_class_id)

        @node_group_class_membership = membership

        # TODO replace with a real method that checks conflicts
        @conflicts = @node_group_class_membership.parameters.length == 0
        if @conflicts
          render :edit
       else
          redirect_to @node_group_class_membership
        end
      }
    end
  end
end
