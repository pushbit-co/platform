module AuthHelpers
  def login(user)
    Pushbit::App.any_instance.should_receive(:authenticate!).and_return(user)
    Pushbit::App.any_instance.should_receive(:current_user).and_return(user)
  end
end
