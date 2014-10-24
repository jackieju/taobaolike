# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_taobaolike_session',
  :secret      => '0cae9ce7ae1d1250ceaeb3728ab0fbf7d6e3eb9f076f2d2b2c0a9d911875365085decb2e7e227b847d940e4e43841c40ca0380311ec6246a8bfc3649ef90e5e6'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
