module Pages
  module Sections
    class ProfileForm < SitePrism::Section
      element :global_error, '.alert.alert-error'

      element :surname, '#person_surname'
      element :surname_error, '.person_surname .error'

      element :save, 'input[type=submit]'
    end
  end
end