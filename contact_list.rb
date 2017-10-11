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
    sql = "SELECT * FROM contacts ORDER BY name ASC"
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

  def add_contact(name, phone, email, category)
    sql = "INSERT INTO contacts (name, phone, email, category) VALUES ($1, $2, $3, $4)"
    query(sql, name, phone, email, category)
  end

  def edit_contact(id, name, phone, email, category)
    sql = "UPDATE contacts SET name = $1, phone = $2, email = $3, category = $4 WHERE id = $5"
    query(sql, name, phone, email, category, id)
  end

  def delete_contact(id)
    sql = "DELETE FROM contacts WHERE id = $1"
    query(sql, id)
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

post "/new_contact" do
  contact_name = params[:name].strip
  error = error_for_name(contact_name)
  if error
    session[:message] = error
    erb :new_contact
  else
    @storage.add_contact(contact_name, params[:phone_number].to_i, params[:email], params[:category])
    session[:message] = "New contact added."
    redirect "/contacts"
  end

end

get "/contacts/:contact_id/edit" do
  contact_id = params[:contact_id].to_i
  @contact = @storage.contact_info(contact_id)
  erb :edit_contact
end

post "/contacts/:contact_id" do
  contact_id = params[:contact_id].to_i
  @storage.edit_contact(contact_id, params[:name], params[:phone_number].to_i, params[:email], params[:category])
  session[:message] = "Contact updated."

  redirect "/contacts"
end

post "/contacts/:contact_id/delete" do
  contact_id = params[:contact_id].to_i
  @storage.delete_contact(contact_id)
  session[:message] = "Contact deleted."

  redirect "/contacts"
end
