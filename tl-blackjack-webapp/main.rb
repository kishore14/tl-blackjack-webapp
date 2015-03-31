require 'rubygems'
require 'sinatra'

#set :sessions, true
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'

BLACKJACK_AMT = 21
DEALER_MIN_HIT = 17

helpers do
	def calculate_total(cards)
		hand_values = cards.map { |card| card[1]} 
	    total = 0
	    hand_values.each do |value|
		    if value == 'A'
		      total += 11
		    elsif value.to_i == 0 # this is for J, Q, K
		      total += 10
		    else
		      total += value.to_i
		    end
		end 
	    hand_values.select{ |value| value == "A" }.count.times do #correction for Aces
	    	total -= 10 if total >BLACKJACK_AMT
	    end
	total
	end
	
	def card_image(card)  
		suit = case card[0]
		when 'H' then 'hearts'
		when 'D' then 'diamonds'
		when 'S' then 'spades'
		when 'C' then 'clubs'
		end

		value = card[1]
		if ['J','Q','K','A'].include?(value)
			value = case card[1]
			when 'J' then 'jack'
			when 'Q' then 'queen'
			when 'K' then 'king'
			when 'A' then 'ace'
			end
		end
		"<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'/>"
	end

	def winner!(msg)
		@play_again = true
		@show_hit_or_stay_buttons = false
		@success = "<strong>#{session[:player_name]} wins!</stong> #{msg}"  
	end

	def loser!(msg)
		@play_again = true
		@show_hit_or_stay_buttons = false
		@error = "<strong>#{session[:player_name]} loses.</stong> #{msg}"  
	end

	def tie!(msg)
		@play_again = true
		@show_hit_or_stay_buttons = false
		@success = "<strong>Its a tie!</stong> #{msg}"  
	end
end

before do
	@show_hit_or_stay_buttons = true
end

get '/' do 
		redirect '/new_player'
end

get '/new_player' do
	erb :new_player
end

post '/new_player' do
	if params[:player_name].empty?
		@error = "Name is required."
		halt erb(:new_player)
	end
	session[:player_name]=params[:player_name]
	redirect '/game'
end

get '/game' do
	session[:turn] = session[:player_name]
	#1 display initial values
	#create a deck and put it in session hash
	suits = ['H','S','D','C']
	values = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
	session[:deck] = suits.product(values).shuffle!

	#deal cards
	session[:dealer_cards] = []
	session[:player_cards] = []
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	#2 render template
	erb :game
end

post '/game/player/hit' do
	session[:player_cards] << session[:deck].pop
	player_total = calculate_total(session[:player_cards])
	if player_total == BLACKJACK_AMT
		winner!("#{session[:player_name]} hit blackjack.")
	elsif player_total > BLACKJACK_AMT
		loser!("Sorry, #{session[:player_name]} is busted." )
	end
	erb :game
end

post '/game/player/stay' do
	@success = "#{session[:player_name]} has chosen to stay!"
	@show_hit_or_stay_buttons = false
	redirect '/game/dealer'
end

get '/game/dealer' do
	@show_hit_or_stay_buttons = false
	session[:turn] = "dealer"

	dealer_total = calculate_total(session[:dealer_cards])

	if dealer_total == BLACKJACK_AMT
		loser!("Sorry, dealer hit blackjack")
	elsif dealer_total > BLACKJACK_AMT
		winner!("Dealer busted at #{dealer_total}.")
	elsif dealer_total >= DEALER_MIN_HIT
		redirect '/game/compare'
	else
		@show_dealer_hit_button = true
	end

	erb :game
end

post '/game/dealer/hit' do
	session[:dealer_cards] << session[:deck].pop
	redirect '/game/dealer'
end

get '/game/compare' do
	@show_hit_or_stay_buttons = false
	player_total = calculate_total(session[:player_cards])
	dealer_total = calculate_total(session[:dealer_cards])

	if player_total < dealer_total
		loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
	elsif player_total > dealer_total
		winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
	else
		tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}.")
	end
	erb :game
end

get '/game_over' do
	erb :game_over
end