class ProfilePhoto < ActiveRecord::Base
  has_one :person
  mount_uploader :image, PersonImageUploader
  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h
end
