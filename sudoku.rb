require 'sinatra'
require 'newrelic_rpm'
require 'rack-flash'
require 'sinatra/partial'
require_relative './lib/sudoku'
require_relative './lib/cell'
require_relative './helpers/application'


enable :sessions
use Rack::Flash
set :partial_template_engine, :erb
set :session_secret, "123456"

def random_sudoku
  seed = (1..9).to_a.shuffle + Array.new(81-9, 0)
  sudoku = Sudoku.new(seed.join) 
  sudoku.solve!
  sudoku.to_s.chars
end

def puzzle(sudoku)
  level = session[:level] ||= 0.3
  sudoku.map {|x| rand < level.to_f ? 0 : x} 
end

get '/easy' do
  session.clear
  redirect '/'
end

get '/hard' do
  session.clear
  redirect '/'
end

post '/difficulty' do
  session[:current_solution] = nil
  session[:level] = params[:level]
  redirect to("/")
end

get '/' do
  prepare_to_check_solution
  generate_new_puzzle_if_necessary
  @current_solution = session[:current_solution] || session[:puzzle]
  @solution = session[:solution]
  @puzzle = session[:puzzle]
  erb :index
end

post '/' do
  cells = (params["cell"])  
  session[:current_solution] = box_order_to_row_order(cells)
  session[:check_solution] = true
  redirect to("/")
end

get '/solution' do
  @current_solution = session[:solution]
  erb :index
end
 
post '/solution' do
  session[:current_solution] = session[:solution]
  redirect to("/")
end

def prepare_to_check_solution
  if @check_solution = session[:check_solution]
     @check_solution
    flash[:notice] = "Incorrect values are highlighted in yellow"
  end
  session[:check_solution] = nil
end



get '/help' do
  erb :help
end

get '/reset' do
  session[:current_solution] = session[:puzzle]
  redirect to("/")
end

def generate_new_puzzle_if_necessary
  return if session[:current_solution] && session[:solution] && session[:puzzle]
  sudoku = random_sudoku
  session[:solution] = sudoku
  session[:puzzle] = puzzle(sudoku)
  session[:current_solution] = session[:puzzle]    
end



def box_order_to_row_order(cells)
  boxes = cells.each_slice(9).to_a
  (0..8).to_a.inject([]) {|memo, i|
    first_box_index = i / 3 * 3
    three_boxes = boxes[first_box_index, 3]
    three_rows_of_three = three_boxes.map do |box| 
      row_number_in_a_box = i % 3
      first_cell_in_the_row_index = row_number_in_a_box * 3
      box[first_cell_in_the_row_index, 3]
    end
    memo += three_rows_of_three.flatten
  }
end





