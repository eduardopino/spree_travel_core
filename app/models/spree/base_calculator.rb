module Spree
  class BaseCalculator

    def generate_all_combinations(product)
      product.rates.each do |rate|
        result = generate_combination(rate)
      end
    end

    def generate_combinations(rate)
      product = rate.variant.product
      old_combinations  = product.combinations.pluck(:id)
      keep_combinations = []
      new_combinations  = []
      for adults in 1..MAX_ADULTS
        for children in 1..MAX_CHILDREN
          price = get_rate_price(rate, adults, children)
          combination = Spree::Combinations.where(:rate_id => rate.id)
          combination = combination.where(:product_id => product.id)
          combination = combination.where(:start_date => rate.start_date.to_date)
          combination = combination.where(:end_date => rate.end_date.to_date)
          combination = combination.where(:adults => adults)
          combination = combination.where(:children => children)
          combination = combination.where(:other => combination_string(rate))
          the_combination = combination.first
          if the_combination
            keep_combinations << the_combination.id
          else
            the_combination = combination.first_or_create!(:price => price)
            new_combinations << the_combination.id
          end
        end
      end
      deleted_combinations = old_combinations - keep_combinations
      Spree::Combinations.where(:id => deleted_combinations).delete_all

      {
        :original => old_combinations,
        :created => new_combinations,
        :deleted => deleted_combinations,
        :kept => keep_combinations,
      }
    end

    def destroy_combinations(rate)
      rate.combinations.delete_all
    end

  end
end