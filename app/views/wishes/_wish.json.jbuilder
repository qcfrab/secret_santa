json.extract! wish, :id, :title, :description, :url, :user_id, :created_at, :updated_at
json.url wish_url(wish, format: :json)
