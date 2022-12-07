module BxBlockWishlist
  class DestroyWishList

    def initialize(id)
      @id = id
    end

    def call
      WishlistItem.find_by(id: @id).destroy
    end
  end
end