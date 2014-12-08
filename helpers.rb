require 'nbasalaryscrape'

module Helpers

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

    def new_income(req)
      income = Income.new
      income.description = req['description'].to_json
      income.teamname = req['teamname'].to_json
      income.playername1 = req['playername1'].to_json
      income.playername2 = req['playername2'].to_json
      income
    end

end
