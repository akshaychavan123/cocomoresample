module AccountBlock
  class GuestAccount < Account
    include Wisper::Publisher
  end
end
