module Pushbit
  class App < Sinatra::Base
    
    get '/auth/login' do
      warden.authenticate!
      
      redirect '/'
    end
    
    get '/auth/login/private' do
      warden.authenticate!(:scope => :private)
       
      redirect '/'
    end
    
    get '/auth/logout' do
      warden.logout
      
      flash[:notice] = 'Successfully logged out'
      redirect '/'
    end

    post '/auth/unauthenticated' do
      session[:return_to] = env['warden.options'][:attempted_path]
      redirect '/auth/login'
    end
  end
end
