module Pushbit
  class RepoBehavior < ActiveRecord::Base
    belongs_to :repo
    belongs_to :behavior
  end
end