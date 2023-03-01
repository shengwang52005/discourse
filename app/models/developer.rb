# frozen_string_literal: true

class Developer < ActiveRecord::Base
  belongs_to :user

  after_save :rebuild_cache
  after_destroy :rebuild_cache

  def self.id_cache
    @id_cache ||= LiveCache.new("developer_ids", 1)
  end

  def self.user_ids
    id_cache.getset("ids") { Set.new(Developer.pluck(:user_id)) }
  end

  def self.rebuild_cache
    id_cache.clear
  end

  def rebuild_cache
    Developer.rebuild_cache
  end
end

# == Schema Information
#
# Table name: developers
#
#  id      :integer          not null, primary key
#  user_id :integer          not null
#
# Indexes
#
#  index_developers_on_user_id  (user_id) UNIQUE
#
