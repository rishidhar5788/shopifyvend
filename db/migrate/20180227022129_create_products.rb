class CreateProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :products do |t|
      t.text :sku
      t.text :product_name
      t.text :quantity
      t.text :price
      t.text :shop

      t.timestamps
    end
  end
end
