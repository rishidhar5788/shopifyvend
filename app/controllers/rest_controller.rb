class RestController < ApplicationController
	require 'httparty'

	skip_before_action :verify_authenticity_token

	# get all shopify products and check if vend product with same SKU is present
	def getShopifyShopProducts
		begin
			shopify_shop_url = "https://" + ENV["SHOPIFY_API_KEY"] + ":" + ENV["SHOPIFY_PASSWORD"] + "@" + ENV["SHOPIFY_SHOP_NAME"] +".myshopify.com/admin/products.json"
			shopify_product_response = HTTParty.get(shopify_shop_url)
			p shopify_product_response
			shopify_product_response["products"].each do |product|
				shop_check_shopify = Product.where(sku: product["variants"][0]["sku"], shop: 'vend').or(Product.where(sku: product["variants"][0]["sku"], shop: 'shopify'))
				if shop_check_shopify.length == 0
					Product.new(shop: "shopify", product_name: product["title"].to_s,
					sku: product["variants"][0]["sku"].to_s, quantity: product["variants"][0]["inventory_quantity"].to_s,
					price: product["variants"][0]["price"].to_s).save
				end
			end
			render :json => {success: true}
		rescue Exception => e
			p "Something went wrong while creating shopify products :::::::::" + e.to_s
		end
	end

	# get all vend products and check if shopify product with same SKU is present
	def getVendShopProducts
		begin
			url_product = "https://" + ENV["VEND_SHOP_NAME"] + ".vendhq.com/api/2.0/products"
			vend_product_response = HTTParty.get(url_product,
				"headers": { 
					"Authorization": "Bearer " + ENV["VEND_ACCESS_TOKEN"], 
					"Content-Type" => 'application/x-www-form-urlencoded'
					})
			
				vend_product_response.parsed_response["data"].each do |product|
					shop_check_vend = Product.where(sku: product["sku"], shop: 'shopify').or(Product.where(sku: product["sku"], shop: 'vend'))
					if shop_check_vend.length == 0
						url_inventory = "https://" + ENV["VEND_SHOP_NAME"] + ".vendhq.com/api/2.0/products/" + product["id"] + "/inventory"	
						response_inventory = HTTParty.get(url_inventory,
							"headers": { 
								"Authorization": "Bearer "+ ENV["VEND_ACCESS_TOKEN"], 
								"Content-Type" => 'application/x-www-form-urlencoded'
								})
						p response_inventory
						if response_inventory["data"].length != 0
							Product.new(shop: "vend", product_name: product["name"].to_s,
							sku: product["sku"].to_s, quantity: response_inventory["data"][0]["inventory_level"].to_s,
							price: product["price_including_tax"].to_s).save
						end
					end
				end
			render :json => {success: true}
		rescue Exception => e
			p "Something went wrong while creating vend products :::::::::" + e.to_s
		end
	end

	# get all the product details from the databse
	def getStitchProducts
		begin
			all_products = Product.all
			render :json => {data: all_products}
		rescue Exception => e
			p "Something went wrong while retreiving stitchlite products :::::::::" + e.to_s
		end
	end

	#get product by product_id
	def getStitchProductsById
		begin
			product_by_id = Product.where(id: params[:id])
			render :json => {data: product_by_id}
		rescue Exception => e
			p "Something went wrong while retreiving stitchlite product by ID :::::::::" + e.to_s
		end
	end	

	#sync products
	def syncProducts
		begin
			shopify_shop_url = "https://" + ENV["SHOPIFY_API_KEY"] + ":" + ENV["SHOPIFY_PASSWORD"] + "@" + ENV["SHOPIFY_SHOP_NAME"] +".myshopify.com/admin/products.json"
			shopify_product_response = HTTParty.get(shopify_shop_url)
			product_sync_shopify = Product.all
			url_product = "https://" + ENV["VEND_SHOP_NAME"] + ".vendhq.com/api/2.0/products"
			vend_product_response = HTTParty.get(url_product,
				"headers": { 
					"Authorization": "Bearer " + ENV["VEND_ACCESS_TOKEN"], 
					"Content-Type" => 'application/x-www-form-urlencoded'
				})

			shopify_product_response["products"].each do |product|
				Product.update_all({shop: "shopify", product_name: product["title"],quantity: product["variants"][0]["inventory_quantity"],
					price: product["variants"][0]["price"].to_s}, {sku: product["variants"][0]["sku"].to_s})
			end

			vend_product_response.parsed_response["data"].each do |product|
				url_inventory = "https://" + ENV["VEND_SHOP_NAME"] + ".vendhq.com/api/2.0/products/" + product["id"] + "/inventory"	
				response_inventory = HTTParty.get(url_inventory,
					"headers": { 
						"Authorization": "Bearer "+ ENV["VEND_ACCESS_TOKEN"], 
						"Content-Type" => 'application/x-www-form-urlencoded'
						})
				p response_inventory
				if response_inventory["data"].length != 0
					Product.update({shop: "vend", product_name: product["name"].to_s,
					quantity: response_inventory["data"][0]["inventory_level"].to_s,
					price: product["price_including_tax"].to_s}, {sku: product["sku"].to_s})
				end
			end

		rescue Exception => e
			p "Something went wrong while syncing products :::::::::" + e.to_s
		end
	end

	# test endpoint
	def test
		render :json => {success: "test endpoint"}
	end
end