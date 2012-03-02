# Helper methods defined here can be accessed in any controller or view in the application

require 'ruby-poker'

SamplePokerBot.helpers do
  # def simple_helper_method
  #  ...
  # end
  
  def formatCards(hand)
    fhand=[]
    hand.each do|card|
      val=card[:value].to_i
      suit=card[:suit]
      if val>9
        valhash=[10=>'T',11=>'J',12=>'Q',13=>'K',14=>'A']
        val=valhash[val]
      end
      fcard=val.to_s+suit
      fhand << fcard
    end
    return fhand
   end
  
  def bet(hand,community,chips, minbet)
    hand=formatCards(hand)
    hand=formatCards(community)
    hand1 = PokerHand.new(community+hand)
    com = PokerHand.new(community)
    if hand1>com
      amount=minbet
      raise_amount = rand(20) < 2 ? (0.1*chips).ceil : 0
      #randomly raise or bet
      if amount + raise_amount < 
        amount += raise_amount
      end
      return { :action => "bet", :amount => amount }
    else
      if minbet > 0.5*chips
        return { :action => "fold"}
      else
        return { :action => "bet", :amount => minbet }
      end
    
    end
    
    
  end
end
