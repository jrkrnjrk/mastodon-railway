# frozen_string_literal: true

username = ENV["ADMIN_USERNAME"].to_s.strip
email    = ENV["ADMIN_EMAIL"].to_s.strip.downcase
password = ENV["ADMIN_PASSWORD"].to_s

if username.empty? || email.empty? || password.empty?
  puts "Admin bootstrap skipped (set ADMIN_USERNAME, ADMIN_EMAIL, ADMIN_PASSWORD)."
  exit 0
end

if password.length < 8
  warn "ADMIN_PASSWORD must be at least 8 characters."
  exit 1
end

account = Account.find_local(username)
user = account&.user || User.find_by(email: email)

if user
  user.email = email
  user.password = password
  user.password_confirmation = password
  user.confirmed_at ||= Time.now.utc
  user.approved = true
  user.disabled = false
  owner = UserRole.find_by(name: "Owner")
  user.role = owner if owner && (user.role.nil? || user.role.name != "Owner")
  user.save!
  puts "Updated existing admin @#{user.account.username} <#{user.email}>"
  exit 0
end

role = UserRole.find_by(name: "Owner")

user = User.new(
  email: email,
  password: password,
  password_confirmation: password,
  confirmed_at: Time.now.utc,
  approved: true,
  agreement: true,
  role: role,
  account_attributes: {
    username: username
  }
)

user.save!
puts "Created admin @#{user.account.username} <#{user.email}>"
