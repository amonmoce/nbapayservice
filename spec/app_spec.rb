require_relative 'spec_helper'
require_relative 'support/story_helpers'
require 'json'

describe 'TeamPay Stories' do
  include StoryHelpers

  describe 'Getting the root of the TeamPay Service' do
    it 'Should return ok' do
      get '/'
      last_response.must_be :ok?
    end
  end

  describe 'Getting Team information' do
    it 'should return their Salary Information' do
      get '/api/v1/MIA.json'
      last_response.must_be :ok?
    end
    it 'should return 404 for unknown team' do
      get "/api/v1/#{random_str(20)}.json"
      last_response.must_be :not_found?
    end
  end

  describe "Getting all team players' names" do
    it 'should return all Team members for the Dallas Mavericks' do
      get '/api/v1/players/DAL.json'
      last_response.must_be :ok?
    end
    it 'should return 404 for unknown team' do
      get "/api/v1/players/#{random_str(20)}.json"
      last_response.must_be :not_found?
    end
  end

  describe 'TeamPayApp' do
    it "should return of two Phoenix players' salaries" do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = { teamname: 'PHO',
               playername1: 'Archie Goodwin',
               playername2: 'Marcus Morris' }
      post '/api/v1/check', body.to_json, header
      last_response.must_be :ok?
    end

    it 'should return 404 for unknown players' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = { teamname: random_str(15),
               playername1: random_str(30) }
      post '/api/v1/check', body.to_json, header
      last_response.must_be :not_found?
    end

    it 'should return 400 for bad JSON formatting' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = random_str(50)
      post '/api/v1/check', body, header
      last_response.must_be :bad_request?
    end
  end

  describe "Difference in two Phoenix players' salaries" do

    before do
      Income.delete_all
    end

    it 'should find the difference in total salaries of the two players below' do

      header = { 'CONTENT_TYPE' => 'application/json' }
      body =  {
                teamname: 'PHO',
                playername1: 'Archie Goodwin',
                playername2: 'Marcus Morris'
              }
      post '/api/v1/comparisons', body.to_json, header

      last_response.must_be :redirect?
      next_location = last_response.location
      next_location.must_match /api\/v1\/comparisons\/\d+/

      # Check if request parameters are stored in ActiveRecord data store
      income_id = next_location.scan(/comparisons\/(\d+)/).flatten[0].to_i
      save_income = Income.find(income_id)
      save_income[:teamname].must_equal body[:teamname]


      # Check if redirect works
      follow_redirect!
      last_request.url.must_match /api\/v1\/comparisons\/\d+/

    end
    it 'should return 404 for unknown users' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = {
              teamname: random_str(15),
              playername1: random_str(30),
              playername2: random_str(30)
              }
      post '/api/v1/comparisons', body.to_json, header

      last_response.must_be :redirect?
      follow_redirect!
      last_response.must_be  :not_found?
    end
    it 'should return 400 for bad JSON formatting' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = random_str(50)
      post '/api/v1/comparisons', body, header
      last_response.must_be :bad_request?
    end
  end

  describe "should return two Phoenix players' salaries" do
    it 'should find total salaries of the two players below' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body =  { teamname: 'PHO',
                playername1: 'Archie Goodwin'
                 }
      post '/api/v1/check2', body.to_json, header
      last_response.must_be :ok?
    end
    it 'should return 404 for unknown users' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = { teamname: random_str(15), playername1: random_str(30) }
      post '/api/v1/check2', body.to_json, header
      last_response.must_be :not_found?
    end
    it 'should return 400 for bad JSON formatting' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = random_str(50)
      post '/api/v1/check2', body, header
      last_response.must_be :bad_request?
    end
  end

  describe 'Check for teams salary' do
    before do
      Income.delete_all
    end

    it "should find players' salary" do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = {
        description: "Team players' salary",
        teamname: 'PHO',
        playername1: 'Archie Goodwin',
        playername2: 'Marcus Morris'
                  }

      # Check redirect URL from post request
      post '/api/v1/playertotal', body.to_json, header
      last_response.must_be :redirect?
      next_location = last_response.location
      next_location.must_match /api\/v1\/playertotal\/\d+/

      # Check if request parameters are stored in ActiveRecord data store
      income_id = next_location.scan(/playertotal\/(\d+)/).flatten[0].to_i
      save_income = Income.find(income_id)
      save_income[:teamname].must_equal body[:teamname]


      # Check if redirect works
      follow_redirect!
      last_request.url.must_match /api\/v1\/playertotal\/\d+/
    end

    it 'should return 404 for unknown players and team' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = {
        description: 'Checking for invalid team',
        playername1: random_str(15),
        playername2: random_str(15),
        teamname: random_str(30)
      }

      post '/api/v1/playertotal', body.to_json, header

      last_response.must_be :redirect?
      follow_redirect!
      last_response.must_be :not_found?
    end

    it 'should return 400 for bad JSON formatting' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = random_str(50)

      post '/api/v1/playertotal', body, header
      last_response.must_be :bad_request?
    end
  end
end
