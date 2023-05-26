#Tracks resources and transactions for each player and Treasury of the Crown
class Coffer
  attr_reader :gold, :food, :prestige

  def initialize(amounts={})
    @gold = amounts[:gold] || 0
    @food = amounts[:food] || 0
    @prestige = amounts[:prestige] || 0
  end

  def give(amounts)
    @gold += amounts[:gold] || 0
    @food += amounts[:food] || 0
    @prestige += amounts[:prestige] || 0
  end

  def take(amounts)
    give(amounts.transform_values { |x| -1 * x })
    @gold = [@gold, 0].max
    @food = [@food, 0].max
    @prestige = [@prestige, 0].max
  end

  def show
    "[#{@gold}, #{@food}, #{@prestige}]"
  end

end

