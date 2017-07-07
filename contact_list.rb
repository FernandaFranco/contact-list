require "sinatra"
require "sinatra/reloader"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  session[:contacts] ||= {"Lucas" => {id: 1, phone_number: 6173866111, email: "lucasaelima@gmail.com", category: :family},
               "Hellen" => {id: 2, phone_number: 4231231234, email: "hellenita@gmail.com", category: :friends},
               "Holly" => {id: 3, phone_number: 1234567890, email: "hollygraph@gmail.com", category: :friends},
               "Maggie" => {id: 4, phone_number: 3211231235, email: "margaritta@gmail.com", category: :work}}

end

get "/" do

  redirect "/contacts"
end

get "/contacts" do
  @contacts = session[:contacts]
  @contact_names = @contacts.keys.sort
  @remaining = %w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)

  erb :contacts
end

get "/contacts/:contact_id" do
  @contacts = session[:contacts]
  contact_id = params[:contact_id].to_i
  contact = @contacts.select { |contact, info| info[:id] == contact_id}
  @contact_name = contact.keys[0]
  @contact_info = contact[@contact_name]
  erb :contact_page
end

get "/new_contact" do
  erb :new_contact
end

post "/new_contact" do
  session[:contacts][params[:name]] = {id: 70, phone_number: params[:phone].to_i, email: params[:email], category: params[:category].to_s}
  session[:message] = "New contact added."

  redirect "/"
end
