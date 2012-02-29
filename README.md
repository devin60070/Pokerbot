# Enova Hackathon - Sample Poker Bot

## Introduction

This Padrino application simply spins up a simple server that fulfills the two basic duties of a poker bot:

1. Registers with the tournament server
2. Responds to the tournament server's inquiries


## Installation

You just need Ruby installed (http://www.ruby-lang.org/en/downloads/) along with the RubyGems package manager and Git (http://git-scm.com/).

Then, clone this repo to somewhere on your computer. From the command-line, that'd be:

  git clone https://rnubel@github.com/rnubel/poker_bot.git poker_bot

Next, install the app's dependencies. Our first step here is to use RubyGems to install Bundler, which will handle our gem dependencies for us.
  
  cd poker_bot

  # You may need to sudo this command.
  gem install bundler   

  # Install all dependencies.
  bundle install

At this point you should be able to spin up the bot on a port of your choice (3000 is the default):

  bundle exec padrino start -p 3000


## Controlling

The only point where you need to control the bot is when registering for the tournament. This can be done many ways, but
this bot provides an interface at http://localhost:3000/manage to do it via the web.

Once registered, the tournament will be pinging your bot directly, so no input is needed from you. Your bot will have to respond 
with the correct action on its own.


## Tournament Server Interface Specification

The only interface defined for the server is the registration endpoint. 

### Registration

  POST <tournamenthost>/tournament/register

Your POST headers must contain the following parameters:
  
  hostname    - Your bot's hostname. E.g., 10.23.221.24:3000
  name        - Your bot/team name. Please also include your netid(s). E.g., Bot Awesome (rnubel2)

As a CURL request, this would look like:

  curl --data "hostname=localhost:3001&name=Bot%20Awesome" localhost:3000/tournament/register

In Ruby, using RestClient (like this bot does), it's just:

  RestClient.post("localhost:3000/tournament/register", { :name => "Bot Awesome", :hostname => "localhost:3001" })


## Bot Interface Specification

Your bot must implement at least the first three of these interfaces. The fourth, _notify_, is not implemented by this bot. However, if you wish to develop a more intelligent bot that tracks game state, you will likely want to be implementing the notification interface.

### Readiness Check (ping)
In order for a registered bot to play in the tournament, the tournament server will first check that the bot
is capable of responding to HTTP requests. The server will do this by making a GET request to:

  GET <hostname>/player/ready

  No parameters are passed.

In order to be seated and have any chance of winning, your bot *must* respond to this with a 200 status code (HTTP 200/OK).

For example, if you registered with your bot's hostname as www.google.com (not recommended), this request would hit www.google.com/player/ready and get a 404 Not Found error. Thus, the bot would not be entered into the tournament.

You can simulate this call to your bot with:

  curl localhost:3000/player/ready


### Seating Confirmation

When the tournament has decided how to seat the available players, it will make a second round of requests to notify each player of their seat. If for some reason you return a non-200 status code, you will not be seated and will not enter the tournament. Similar to the ready-check, your bot should just return 200 OK. Also, if your bot is stateful, this is a good time to reset your state (or create a new table object based off of the game_table_identifier that's passed with the request).

  POST <hostname>/player/seat

  game_table_identifier - Unique identifier of the game table.

You can simulate this call to your bot with something like:

  curl --data "game_table_identifier=game_table_4" localhost:3000/player/seat

### Get Action

Finally, the important call -- this interface is how the tournament gets your bot's actual action in a round. First, there are three types of allowed actions:

- *blind*: Post blinds. In each hand, the first two players are required to post a small blind (1 chip) and large blind (2 chips) respectively. If you fail to post exactly these blinds, you will be unseated from the tournament. 
- *bet*: Set your bet to the passed-in *amount*. Note that we don't distinguish between raising and calling; the arguments to this action will tell you what the minimum bet is and it's up to your bot to decide whether it will match it or raise it.
- *fold*: This is the default action if you fail to make a valid other action. Note that, if you fold when you are supposed to post blinds, you will be unseated (so don't!).

With that out of the way, here's the call that the server will make. Note the large number of parameters!

  POST <hostname>/player/action

  minimum_bet
  maximum_bet
  blind           - If this is "true", YOU MUST RETURN action=blind, amount=minimum_bet!!
  your_chips      - Number of chips you have (*excluding* your current bet in this round. This is so you can always compare minimum_bet to your_chips to see if you can meet the minimum).
  your_hand       - This is an array of your two cards. Each card has a value and suit. So, accessing them works like your_hand[0][suit] to get "S".
    suit
    value
  community_cards - This is an array of the community cards that have been dealt so far, in the same format.
    suit
    value
  game_table_identifier - A way to uniquely ID the table you're playing at.
  hand_identifier - A way to identify the hand you're currently playing.
  betting_phase   - Either 'pre_flop', 'flop', 'turn', or 'river'. Note that a betting "phase" and "round" are the same thing.
  active_players  - An array of the other active players. Each player contains the following hash of data:
    name                  - Name of this player. Should be unique.
    chips                 - Current number of chips excluding the current bet in the round.
    actions_this_round    - Another array!
      action              - "fold", "bet", "blind"
      amount              - Can be blank.


This is a lot of data, but we're doing that to make it easier for you! You can write a fairly intelligent bot without having to track game state, and just using the data passed in.

You can simulate this with a call like:

  curl --data "minimum_bet=2&maximum_bet=2&blind=true&your_chips=1&your_hand[0][suit]=D&your_hand[0][value]=3&your_hand[1][suit]=S&your_hand[1][value]=9&game_table_identifier=table_3&hand_identifier=hand_21&betting_phase=pre_flop&active_players[0][name]=Bob&active_players[0][chips]=1&active_players[1][name]=Alice&active_players[1][chips]=19&active_players[1][actions_this_round][0][action]=blind&active_players[1][actions_this_round][0][amount]=1" localhost:3000/player/action


### Notifications

If your bot is keeping track of game state, there are a few events you may want to know about that aren't passed in the above interface or are tricky to glean from it. Those events are:

- You have folded (or made an invalid action and were forced to fold)
- You have been unseated
- You have won chips
- The hand has concluded

All these events are posted through the same interface, but the data changes with each.

  POST <hostname>/player/notify

  event - either folded, unseated, won_chips, or hand_ended

  Parameters for folded: None
  
  Parameters for unseated: None
  
  Parameters for won_chips: 
    amount - How many chips were won from the pot.

  Parameters for hand_ended:
    winners - Array of winners, with the key of each cell being the winner's name and containing a hash of:
      hand - Array of cards
        suit
        value
      chips_received - Number of chips this person won.


You can simulate the last one (the first three are simple enough for you to figure out) with a call like:

  curl --data "event=hand_ended&winners[Alice][chips_received]=1&winners[Alice][hand][0][suit]=S&winners[Alice][hand][0][value]=2&winners[Alice][hand][1][suit]=S&winners[Alice][hand][1][value]=6" localhost:3000/player/notify

