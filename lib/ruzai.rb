require "ruzai/version"
require "active_support"
require "active_support/core_ext"
require "active_record"

module Ruzai
  attr_accessor :suspention_expired_at, :suspended_count
  include ActiveSupport::Configurable
  config_accessor :suspention_duration, :respawn_limit

  self.configure do |config|
    config.suspention_duration = 2.weeks
    config.respawn_limit = 5
  end

  def suspended?
    return true if (self.suspended_count || 0) > Ruzai.respawn_limit
    return false unless suspention_expired_at
    self.suspention_expired_at > Time.now
  end

  def suspended_until
    return nil unless suspention_expired_at
    remains = (self.suspention_expired_at - Time.now).to_i

    # If time remains between 1 second ~ 23 hours 59 seconds, it displays '1 day'
    (( remains / 1.day ) + 1 ).day
  end

  def suspend!
    self.suspended_count ||=0
    self.suspended_count += 1
    self.suspention_expired_at = Ruzai.suspention_duration.from_now
    self.save!
  end

  def ban!
    self.suspended_count = Ruzai.respawn_limit + 1
    self.save!
  end

  def remove_suspention!
    self.suspention_expired_at = nil
    self.save!
  end
end
