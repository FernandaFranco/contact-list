ENV["RACK_ENV"] = "test" # used by sinatra and rack to know if code is being
# tested, and determine if sinatra should start a web server

require "minitest/autorun" # autorun is for automatically running any tests that
# will be defined
require "minitest/reporters"
require "rack/test" # provides helper methods for testing

require_relative "../contact_list"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

class ContactListTest < Minitest::Test
  include Rack::Test::Methods # these helper methods expect a method app to
  # exist and return an instance of a rack application

  def app
    Sinatra::Application
  end

  def testing_contact_list
    { "rack.session" => { contacts: [{id: 1, name: "John Wayne", phone_number: 6172221111, email: "johnnyjohn@gmail.com", category: :friends}] } }
  end

  def setup

  end

  def test_contacts_index
    get "/"
    assert_equal 302, last_response.status

    get last_response["Location"], {}, testing_contact_list
    assert_equal 200, last_response.status
    assert_includes last_response.body, "My Contacts"
    assert_includes last_response.body, "John Wayne"
  end

  def test_contact_page
    get "/contacts/1", {}, testing_contact_list

    assert_equal 200, last_response.status
    assert_includes last_response.body, "John Wayne"
    assert_includes last_response.body, "friends"
    assert_includes last_response.body, "Phone: 6172221111"
    assert_includes last_response.body, "E-mail: johnnyjohn@gmail.com"

    assert_includes last_response.body, "Return"
  end

  def test_add_a_contact_page
    get "/new_contact"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<form"
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, "<select"
    assert_includes last_response.body, "<button"
  end

  def test_adding_a_contact
    post "/new_contact", {name: "Fernanda Frances", phone: "1234567890", email: "franfran@hotmail.com", category: "family" }
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Fernanda Frances"



  end
end
