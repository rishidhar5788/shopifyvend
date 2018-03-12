Rails.application.routes.draw do
  get '/shopify/products', to: 'rest#getShopifyShopProducts'
  get '/vend/products', to: 'rest#getVendShopProducts'
  get '/api/products', to: 'rest#getStitchProducts'
  get '/api/products/:id', to: 'rest#getStitchProductsById'
  post '/api/sync', to: 'rest#syncProducts'
  post '/test', to: 'rest#test'
end
