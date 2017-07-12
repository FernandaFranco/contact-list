require "sinatra"
require "sinatra/reloader"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  session[:contacts] ||= []

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

def next_id(contacts)
  if contacts.empty?
    return 1
  else
    contacts.map { |contact| contact[:id] }.max + 1
  end
end

post "/new_contact" do
  contacts = session[:contacts]
  session[:contacts] << {id: next_id(contacts), name: params[:name], phone_number: params[:phone].to_i, email: params[:email], category: params[:category]}
  session[:message] = "New contact added."

  redirect "/contacts"
end
