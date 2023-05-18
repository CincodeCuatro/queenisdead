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
  end
end