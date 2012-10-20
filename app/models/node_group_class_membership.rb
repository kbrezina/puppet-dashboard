class NodeGroupClassMembership < ActiveRecord::Base
  validates_presence_of :node_class_id, :node_group_id

  has_parameters

  belongs_to :node_class
  belongs_to :node_group
end
