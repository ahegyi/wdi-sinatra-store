# gem install --version 1.3.0 sinatra
require 'pry'
# sinatra/reloader conflicts with later versions of sinatra
gem 'sinatra', '1.3.0'
require 'sinatra'
# "continuous deployment", no need to restart server
require 'sinatra/reloader'
# require 'sinatra/support/numeric'
require 'sqlite3'
gem 'binding_of_caller'
require 'binding_of_caller'
require 'better_errors'
require 'open-uri'
require 'uri'
require 'json'
require 'time'

=begin
class Main < Sinatra::Base
  register Sinatra::Numeric
end

Main.configure do |m|
  m.set :default_currency_unit, '$'
  m.set :default_currency_precision, 2
  m.set :default_currency_separator, ','
end
=end

set :run, true
set :port, 6787

before do
  @db = SQLite3::Database.new "store.sqlite3"
  @db.results_as_hash = true
end

configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = File.expand_path("..", __FILE__)
end

# ================== HELPERS ================== #

class Numeric
  def to_currency(currency="$")
    formatted_float = sprintf("%.2f", self)
    return currency + formatted_float.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\1,')
  end
end

class Time
  def to_time_ago_simple
    seconds = ((Time.now - self).abs).round
    minutes = (((Time.now - self).abs)/60).round
       
    return nil if minutes < 0

    case minutes
    when 0
      case seconds
      when 2..30
        "#{seconds} seconds ago"
      else
        "just now"
      end
    when 1
      "1 minute ago"
    when 1..59
      "#{minutes} minutes ago"
    when 60..119
      "about 1 hour ago"
    when 120..1439
      "about #{(minutes/60).floor} hours ago"
    else
      "a while ago"
    end
  end
end

# ================== HOME ================== #

get '/' do
  erb :home
end

# ================== PRODUCTS ================== #

# ================== GET PRODUCTS ================== #

# GET ALL PRODUCTS
get '/products' do
  redirect '/products/sort/name/asc'
end

# SHOW FORM FOR CREATING A NEW PRODUCT
get '/products/new' do
  @product_details = Hash.new("") # Fake-out for new_product.erb, which uses product_form.erb

  @form_details = {}
  @form_details[:post_path] = '/products'
  @form_details[:legend] = "New Product"

  erb :new_product
end

# SEARCH FOR A PRODUCT
get '/products/search' do
  @q = params[:q]
  file = open("http://search.twitter.com/search.json?q=#{URI.escape(@q)}")

  @results = JSON.load(file.read)

  erb :search_results
end

# GET PRODUCT DETAIL
get '/products/:id' do
  @id = params[:id]

  @rs = @db.execute("SELECT * FROM products WHERE id = ? LIMIT 1", @id)
  @details = @rs.first

  twitter_file = open("http://search.twitter.com/search.json?q=#{URI.escape(@details['name'])}")
  @twitter_results = JSON.load(twitter_file.read)

  goog_shopping_key = "AIzaSyCLbHEfq1BBSfIBLdmAV6wcnAPfQEtKQGo"
  goog_file = open("https://www.googleapis.com/shopping/search/v1/public/products?key=#{goog_shopping_key}&country=US&q=#{URI.escape(@details['name'])}&alt=json", :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE)
  @goog_results = JSON.load(goog_file.read)

  erb :show_product_detail
end

# SHOW FORM FOR EDITING A PRODUCT
get '/products/:id/edit' do
  @id = params[:id]

  @rs = @db.execute("SELECT * FROM products WHERE id = ? LIMIT 1", @id)
  @product_details = @rs.first
  
  @form_details = {}
  @form_details[:post_path] = "/products/#{@product_details['id']}"
  @form_details[:legend] = "Update Product"

  erb :update_product
end

# GET ALL PRODUCTS (with sorting)
get '/products/sort/:orderby/:dir' do
  @rs = @db.execute("SELECT * FROM products ORDER BY #{params[:orderby]} #{params[:dir].upcase};")
  @sort = params

  erb :show_products
end


# ================== POST/PUT/DELETE PRODUCTS ================== #


# CREATE PRODUCT
post '/products' do
  @name = params[:product_name]
  @price = params[:product_price].to_f
  @on_sale = params[:product_on_sale] == "on" ? "t" : "f"
  @created_at = Time.now

  @rs = @db.execute("INSERT INTO products ('created_at', 'name', 'price', 'on_sale') VALUES (?, ?, ?, ?);", @created_at.to_s, @name, @price, @on_sale)

  erb :product_created
end

# UPDATE PRODUCT
post '/products/:id' do
  @id = params[:id]
  @name = params[:product_name]
  @price = params[:product_price].to_f
  @on_sale = params[:product_on_sale] == "on" ? "t" : "f"

  @rs = @db.execute("UPDATE products SET name = ?, price = ?, on_sale = ? WHERE id = ?;", @name, @price, @on_sale, @id)
  
  redirect '/products'
end

# DELETE PRODUCT
delete '/products/:id/destroy' do
  @id = params[:id]
  @rs = @db.execute("DELETE FROM products WHERE id = ?", @id)

  redirect '/products'
end

# ================== USERS ================== #



# ================== GET USERS ================== #

get '/users' do
  redirect '/users/sort/name/asc'
end

get '/users/sort/:orderby/:dir' do
  @rs = @db.prepare("SELECT * FROM users ORDER BY #{params[:orderby]} #{params[:dir].upcase};").execute
  @sort = params

  erb :show_users
end