=begin
  Assigns a random name to a character based on their gender
  TODO : assign a surname to each player based on color (Red,Blue,Green,Yellow,Orange,Purple,Black)
=end
module NameGen 
  
  def initialize
  @file_data_male = File.readlines("ref/malenames.txt").map(&:chomp)
  @file_data_female = File.readlines("ref/femalenames.txt").map(&:chomp)
  end

  def which_gender?(gender)
     case
     when gender == "male"
      return name = @file_data_male.sample
     when gender == "female"
      return name = @file_data_female.sample
     end
    end

end
