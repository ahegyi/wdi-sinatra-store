# gem install --version 1.3.0 sinatra
require 'pry'
gem 'sinatra', '1.3.0'
require 'sinatra'
require 'sinatra/reloader'
# require 'sinatra/support/numeric'
require 'sqlite3'

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

get '/users' do
  redirect '/users/sort/name/asc'
end

get '/users/sort/:orderby/:dir' do
  db = SQLite3::Database.new "store.sqlite3"
  db.results_as_hash = true
  @rs = db.prepare("SELECT * FROM users ORDER BY #{params[:orderby]} #{params[:dir].upcase};").execute
  @sort = params

  erb :show_users
end

get '/products' do
  redirect '/products/sort/name/asc'
end

get '/products/sort/:orderby/:dir' do
  db = SQLite3::Database.new "store.sqlite3"
  db.results_as_hash = true
  @rs = db.execute("SELECT * FROM products ORDER BY #{params[:orderby]} #{params[:dir].upcase};")
#  @rsquestion = db.execute("SELECT * FROM products ORDER BY ? ?;", params[:orderby], params[:dir].upcase)

  @sort = params

  erb :show_products
end

get '/query' do
  "|" + request.query_string + "|" + params.inspect
end

get '/' do
  erb :home
end
 
 
 
 
 
 
 
 
 
=begin
 
  <form method='post' action='/create'>
    <input type='text' name='name' autofocus>
    <input type='text' name='photo'>
    <input type='text' name='breed'>
    <button>dog me!</button>
  </form>
 
 
  post '/create' do
  end
 
 
  redirect '/'
 
=end