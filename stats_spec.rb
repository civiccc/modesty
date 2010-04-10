require 'modesty'

describe "Stats!" do
  before :all do
    Modesty.experiments = {}
    Modesty.metrics = {}
    Modesty.new_metric :bw_creation
    Modesty.new_metric :bw_donation
  end

  it "can make a stat" do
    Modesty.new_experiment :creation_page do
      stat :dollars_per_wish do |metrics|
        wishes = metrics[:bw_creation].users
        dollars = metrics[:bw_donation].total
        wishes.to_f/dollars.to_f
      end
    end
  end
end
