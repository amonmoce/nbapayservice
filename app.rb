require 'sinatra/base'
require 'sinatra'
require 'json'
require_relative 'model/income'
require_relative 'helpers.rb'

# nbasalaryscrape service
class TeamPayService < Sinatra::Base

  configure :production, :development do
    enable :logging
  end

  configure :development do
    set :session_secret, "something"    # ignore if not using shotgun in development
  end

  helpers do
    include Helpers
  end


  delete '/api/v1/comparisons/:id' do
    begin
      Income.destroy(params[:id])
    rescue
      halt 404
    end
  end

  post '/api/v1/comparisons' do
    content_type :json
    body = request.body.read
    logger.info body

    begin
      req = JSON.parse(body)
      logger.info req
    rescue Exception => e
      puts e.message
      halt 400
    end
    incomes = Income.new
    incomes.teamname = req['teamname']
    incomes.playername1 = req['playername1']
    incomes.playername2 = req['playername2']

    if incomes.save
      redirect "/api/v1/comparisons/#{incomes.id}"
    end
  end

  get '/api/v1/comparisons/:id' do
    content_type :json
    logger.info "GET /api/v1/comparisons/#{params[:id]}"
    begin
      @income = Income.find(params[:id])
      teamname = @income.teamname
      playername1 = @income.playername1
      playername2 = @income.playername2
      players = [playername1, playername2]
    rescue
      halt 400
    end

    result = two_players_salary_data(teamname, players).to_json
    logger.info "result: #{result}\n"
    if result.nil? || result.empty?
      halt 404
    else
      result
    end
    result
  end

  delete '/api/v1/playertotal/:id' do
    income = Income.destroy(params[:id])
  end

  post '/api/v1/playertotal' do
    content_type :json
    body = request.body.read
    logger.info body

    begin
      req = JSON.parse(body)
      logger.info req
    rescue Exception => e
      puts e.message
      halt 400
    end
    incomes = Income.new
    incomes.teamname = req['teamname']
    incomes.playername1 = req['playername1']

    if incomes.save
      redirect "/api/v1/playertotal/#{incomes.id}"
    end
  end

  get '/api/v1/playertotal/:id' do
    content_type :json
    logger.info "GET /api/v1/playertotal/#{params[:id]}"
    begin
      @total = Income.find(params[:id])
      teamname = @total.teamname
      playername1 = [@total.playername1]
    rescue
      halt 400
    end

    result = player_total_salary(teamname, playername1).to_json
    logger.info "result: #{result}\n"
    result
  end

  get '/api/v1/:teamname.json' do
      content_type :json
      get_team(params[:teamname]).to_json

  end

  get '/api/v1/players/:teamname.json' do
    content_type :json
    get_team_players(params[:teamname]).to_json
  end

  post '/api/v1/check' do
    content_type :json
    begin
      req = JSON.parse(request.body.read)
    rescue
      halt 400
    end
    teamname = req['teamname']
    playername1 = req['playername1']
    playername2 = req['playername2']
    players = [playername1, playername2]
    player_salary_data(teamname, players).to_json
  end

  post '/api/v1/check2' do
    content_type :json
    begin
      req = JSON.parse(request.body.read)
    rescue
      halt 400
    end
    teamname = req['teamname']
    playername1 = req['playername1']
    playername2 = req['playername2']
    players = [playername1, playername2]
    player_total_salary(teamname, players).to_json
  end

  get '/' do
    'NBA PAY Service api/v1 is up and working at /api/v1/'
  end

  not_found do
    status 404
    'not found'
  end
end
