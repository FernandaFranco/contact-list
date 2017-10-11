require "sinatra"
require "sinatra/reloader"
require "pg"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "contacts")
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def all_contacts
    sql = "SELECT * FROM contacts"
    result = query(sql)

    result.map do |tuple|
      tuple_to_list_hash(tuple)
    end
  end

  def contact_info(contact_id)
    sql = "SELECT * FROM contacts WHERE id = $1"
    result = query(sql, contact_id)

    result = result.map do |tuple|
      tuple_to_list_hash(tuple)
    end

    result.first
  end

  private

  def tuple_to_list_hash(tuple)
   { id: tuple["id"].to_i,
     name: tuple["name"],
     phone: tuple["phone"].to_i,
     email: tuple["email"],
     category: tuple["category"] }
  end
end


# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_name(name)
  if !(1..100).cover? name.size
    "Contact name must be between 1 and 100 characters."
  end
end

get "/" do
  redirect "/contacts"
end

get "/contacts" do
  @contacts = @storage.all_contacts
  @remaining = %w(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)

  erb :contacts
end

get "/contacts/:contact_id" do
  contact_id = params[:contact_id].to_i
  @contact = @storage.contact_info(contact_id)
  erb :contact_page
end

get "/new_contact" do
  erb :new_contact
end

def next_id(contacts)
  if contacts.empty?
    return 1
  else
    contacts.map { |contact| contact[:id].to_i }.max + 1
  end
end

post "/new_contact" do
  contacts = session[:contacts]
  contact_name = params[:name].strip
  error = error_for_name(contact_name)
  if error
    session[:message] = error
    erb :new_contact
  else
    contacts << {id: next_id(contacts), name: contact_name, phone_number: params[:phone_number].to_i, email: params[:email], category: params[:category]}
    session[:message] = "New contact added."
    redirect "/contacts"
  end

end

get "/contacts/:contact_id/edit" do
  contacts = session[:contacts]
  contact_id = params[:contact_id].to_i
  @contact = contacts.find { |contact| contact[:id] == contact_id}

  erb :edit_contact
end

post "/contacts/:contact_id" do
  contacts = session[:contacts]
  contact_id = params[:contact_id].to_i
  contacts.delete_if { |contact| contact[:id] == contact_id}

  contacts << {id: contact_id, name: params[:name], phone_number: params[:phone_number].to_i, email: params[:email], category: params[:category]}
  session[:message] = "Contact updated."

  redirect "/contacts"
end

post "/contacts/:contact_id/delete" do
  contacts = session[:contacts]
  contact_id = params[:contact_id].to_i
  contacts.delete_if { |contact| contact[:id] == contact_id}

  session[:message] = "Contact deleted."

  redirect "/contacts"
end
