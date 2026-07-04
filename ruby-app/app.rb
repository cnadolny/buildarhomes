require 'sinatra'
require 'mail'
require 'securerandom'
require 'cgi'

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET', SecureRandom.hex(64))
  set :public_folder, File.expand_path('../public', __dir__)
  set :views,         File.expand_path('views',     __dir__)
end

helpers do
  def csrf_token
    session[:csrf_token] ||= SecureRandom.hex(32)
  end

  def h(text)
    CGI.escapeHTML(text.to_s)
  end

  def encode_filename(name)
    CGI.escape(name.to_s).gsub('+', '%20')
  end

  def image_files(dir)
    return [] unless Dir.exist?(dir)
    exts = %w[.jpg .jpeg .png .gif .webp]
    Dir.glob(File.join(dir, '*'))
       .select { |f| exts.include?(File.extname(f).downcase) }
       .map    { |f| File.basename(f) }
       .sort
  end
end

before do
  @flash = session.delete(:flash) || {}
  if request.post?
    token = params['_csrf'].to_s
    halt 403, 'Invalid request' unless token == session[:csrf_token]
  end
end

get '/' do
  @title = 'Home'
  erb :home
end

get '/contact' do
  @title = 'Contact'
  erb :contact
end

post '/contact' do
  name    = params[:name].to_s.strip
  email   = params[:email].to_s.strip
  phone   = params[:phonenumber].to_s.strip
  message = params[:message].to_s.strip

  errors = []
  errors << 'Name cannot be blank'    if name.empty?
  errors << 'Email is not valid'      unless email.match?(/\A[^@\s]+@[^@\s]+\z/)
  errors << 'Message cannot be blank' if message.empty?

  if errors.any?
    session[:flash] = { errors: errors }
    redirect '/contact'
    return
  end

  begin
    from_addr = ENV.fetch('EMAIL', '')
    smtp_opts = {
      address:              'mail.privateemail.com',
      port:                 587,
      user_name:            from_addr,
      password:             ENV.fetch('EMAIL_PASSWORD', ''),
      authentication:       'plain',
      enable_starttls_auto: true
    }

    mail = Mail.new do
      from     "AR Builders <#{from_addr}>"
      to       "AR Builders <#{from_addr}>"
      reply_to "#{name} <#{email}>"
      subject  'Contact Form'
      body     "Name: #{name}\nEmail: #{email}\nPhone: #{phone}\nMessage: #{message}"
      delivery_method :smtp, smtp_opts
    end
    mail.deliver!

    session[:flash] = { success: 'Email has been sent successfully!' }
  rescue => e
    $stderr.puts "Email error: #{e.message}"
    session[:flash] = { errors: ['Error sending the message. Please try again shortly.'] }
  end

  redirect '/contact'
end

get '/gallery' do
  @title   = 'Gallery'
  base     = File.join(settings.public_folder, 'images')

  @galleries = [
    { name: 'Linden',    folder: 'Linden'   },
    { name: 'Tuscany',   folder: 'tuscany'  },
    { name: 'Golf View', folder: 'golfview' },
    { name: 'Queens',    folder: 'queens'   },
    { name: 'Glen Oak',  folder: 'glenoak'  },
    { name: 'Fairhope',  folder: 'fairhope' },
  ].map { |g| g.merge(files: image_files(File.join(base, g[:folder]))) }

  erb :gallery
end
