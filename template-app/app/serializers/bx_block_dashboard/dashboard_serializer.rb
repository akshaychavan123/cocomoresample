# == Schema Information
#
# Table name: dashboards
#
#  id         :bigint           not null, primary key
#  title      :string
#  value      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module BxBlockDashboard
  class DashboardSerializer < BuilderBase::BaseSerializer
    attributes :id, :title, :value, :created_at, :updated_at
  end
end
