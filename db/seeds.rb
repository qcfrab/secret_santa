%w[demo1 demo2 demo3].each do |name|
  User.find_or_create_by!(email: "#{name}@example.com") do |user|
    user.password = "password123"
  end
end