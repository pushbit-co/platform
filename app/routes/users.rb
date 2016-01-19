module Pushbit
  class App < Sinatra::Base
    put "/users/me" do
      authenticate!

      current_user.update_attributes!(params)
      redirect back
    end
  end
end