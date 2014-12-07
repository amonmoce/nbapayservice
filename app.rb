require 'sinatra/base'
require 'sinatra'
require 'nbasalaryscrape'
require 'json'
require_relative 'model/income'


# nbasalaryscrape service
class TeamPayService < Sinatra::Base

  configure :production, :development do
    enable :logging
  end

  configure :development do
    set :session_secret, "something"    # ignore if not using shotgun in development
  end

  helpers do
    def get_team(teamname)
      var = SalaryScraper::BasketballReference.new
      begin
      var.to_array_of_hashes(teamname.upcase)
      rescue
        halt 404
      end
    end

    def get_team_players(teamname)
      begin
        team = get_team(teamname)
        team_players = []
        team.each do |player_salary_scrape|
          team_players << player_salary_scrape['Player']
        end
      rescue
        halt 404
      end
      team_players
    end

    def player_salary_data(teamname, player_name)

      begin
        salary_scrape = get_team(teamname)
        player_scrape = []
        player_name.each do |each_player|
          salary_scrape.each do |data_row|
            player_scrape <<  data_row  if data_row['Player'] == each_player
          end
        end
      rescue
        halt 404
      else
        player_scrape
      end
    end

    def one_total(data_row, each_player)
      player_scrape, fullpay = 0, []
      player_scrape +=  parse_money(data_row['2014-15'])
      player_scrape +=  parse_money(data_row['2015-16'])
      player_scrape +=  parse_money(data_row['2016-17'])
      player_scrape +=  parse_money(data_row['2017-18'])
      player_scrape +=  parse_money(data_row['2018-19'])
      player_scrape +=  parse_money(data_row['2019-20'])
      fullpay << { 'player' => each_player,
                   'fullpay' => back_to_money(player_scrape) }
      fullpay
    end

    def player_total_salary(teamname, player_name)
      players = []
      begin
        salary_scrape = get_team(teamname)
        player_name.each do |each_player|
          salary_scrape.each do |data_row|
            if data_row['Player'] == each_player
              players << one_total(data_row, each_player)
            end
          end
        end
      rescue
        halt 404
      end
      if players.length == nil
        halt 404
      end
      players
    end

    def two_players_salary_data(teamname, player_name)
      player_scrape = []
      begin
        salary_scrape = get_team(teamname)

        player_name.each do |each_player|
          salary_scrape.each do |data_row|
            player_scrape << diff_total(data_row, each_player) if data_row['Player'] == each_player
          end
        end
        make_salary_comparisons(player_scrape)
      rescue
        halt 404
      else
        make_salary_comparisons(player_scrape)
      end
    end

    def make_salary_comparisons(player_scrape)
      if player_scrape[0]['fullpay'] > player_scrape[1]['fullpay']
        diff = player_scrape[0]['fullpay'] - player_scrape[1]['fullpay']
        return_string = "#{player_scrape[0]['player']} makes #{back_to_money(diff)} more than #{player_scrape[1]['player']} "
      elsif player_scrape[1]['fullpay'] > player_scrape[0]['fullpay']
        diff = player_scrape[1]['fullpay'] - player_scrape[0]['fullpay']
        return_string = "#{player_scrape[1]['player']} makes #{back_to_money(diff)} more than #{player_scrape[0]['player']} "
      else
        return_string = "#{player_scrape[1]['player']} and #{player_scrape[0]['player']} makes the same salary (#{back_to_money(player_scrape[0]['fullpay'])})"
      end
      return_string
    end

    def diff_total(data_row, each_player)
      player_scrape = 0
      player_scrape += parse_money(data_row['2014-15'])
      player_scrape += parse_money(data_row['2015-16'])
      player_scrape += parse_money(data_row['2016-17'])
      player_scrape += parse_money(data_row['2017-18'])
      player_scrape += parse_money(data_row['2018-19'])
      player_scrape += parse_money(data_row['2019-20'])
      fullpay = { 'player' => each_player,
                  'fullpay' => player_scrape }
      fullpay
    end

    def parse_money(money)
      data = money.gsub(/[$,]/, '$' => '', ',' => '')
      data.to_i
    end

    def back_to_money(data)
      money = "$#{data.to_s.reverse.gsub(/...(?=.)/, '\&,').reverse}"
      money
    end

    def current_page?(path = ' ')
      path_info = request.path_info
      path_info += ' ' if path_info == '/'
      request_path = path_info.split '/'
      request_path[1] == path
    end
  end


  delete '/api/v1/comparisons/:id' do
    income = Income.destroy(params[:id])
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
