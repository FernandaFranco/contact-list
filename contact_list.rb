require "sinatra"
require "sinatra/reloader"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  session[:contacts] ||= [{id: 1, name: "Lucas", phone_number: 6173866111, email: "lucasaelima@gmail.com", category: :family},
               {id: 2, name: "Hellen", phone_number: 4231231234, email: "hellenita@gmail.com", category: :friends},
               {id: 3, name: "Holly", phone_number: 1234567890, email: "hollygraph@gmail.com", category: :friends},
               {id: 4, name: "Maggie", phone_number: 3211231235, email: "margaritta@gmail.com", category: :work}]

end

get "/" do

  redirect "/contacts"
end

get "/contacts" do
  @contacts = session[:contacts]
  @contact_names = @contacts.map { |contact| contact[:name] }.sort
  @remaining = %w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)

  erb :contacts
end

get "/contacts/:contact_id" do
  contacts = session[:contacts]
  contact_id = params[:contact_id].to_i
  @contact = contacts.find { |contact| contact[:id] == contact_id}
  erb :contact_page
end

get "/new_contact" do
  erb :new_contact
end

post "/new_contact" do
  session[:contacts] << {id: 70, name: params[:name], phone_number: params[:phone].to_i, email: params[:email], category: params[:category].to_s}
  session[:message] = "New contact added."

  redirect "/"
end
