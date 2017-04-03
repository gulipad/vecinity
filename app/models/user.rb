class User < ActiveRecord::Base
	serialize :profile
	has_many :favorites
end
