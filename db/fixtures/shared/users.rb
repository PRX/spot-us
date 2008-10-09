unless Rails.env.production?
  testing_users = [
    %w(David Cohn dcohn1@gmail.com),
    %w(Desi McAdam desi@hashrocket.com),
    %w(Jon Larkowski lark@hashrocket.com),
    %w(Carmelyne Thompson carmelyne@hashrocket.com)
  ]

  testing_users.each_with_index do |u, i|
    user_hash = {
      :first_name => u[0],
      :last_name => u[1],
      :password => '12345',
      :password_confirmation => '12345',
    }
  
    original_email = u[2]
  
    # makes three types of users for each tester
    # example:  lark@hashrocket.com
    #           lark+citizen@hashrocket.com
    #           lark+reporter@hashrocket.com
    #           lark+organization@hashrocket.com  
  
    user_hash[:id] = 3*i + 1
    user_hash[:email] = original_email.gsub /@/, "+citizen@"
    user_hash[:type] = Citizen.name
    User.create_or_update user_hash

    user_hash[:id] = 3*i + 2
    user_hash[:email] = original_email.gsub /@/, "+reporter@"
    user_hash[:type] = Reporter.name
    User.create_or_update user_hash
  
    user_hash[:id] = 3*i + 3
    user_hash[:email] = original_email.gsub /@/, "+organization@"
    user_hash[:type] = Organization.name
    User.create_or_update user_hash
  end
end
