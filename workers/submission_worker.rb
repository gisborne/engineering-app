require "json"

class SubmissionWorker
  include Sidekiq::Worker

  def perform(params, remote_ip)
    if pass_recaptcha?(params["g-recaptcha-response"], remote_ip) == false
      puts "Recaptcha failed! #{params["g-recaptcha-response"]}, #{remote_ip}"
      return false
    end

    body = app_body(params)

    Mail.deliver do
      to params[:email]
      from ENV["FROM_EMAIL"]
      subject "Engineering Application Recieved"
      body "Hi there,\nWe've recieved your application. We'll be in touch soon!\n#{body}"
    end

    Mail.deliver do
      from params[:email]
      to ENV["TO_EMAIL"]
      subject "Engineering Application Recieved"
      body "We've recieved an application.\n#{body}"
    end
  end

  def pass_recaptcha?(response, ip)
    res = Net::HTTP.post_form(
      URI.parse("https://www.google.com/recaptcha/api/siteverify"),
      {
        secret: ENV["RECAPTCHA_KEY"],
        remoteip: ip,
        response: response
      }
    )

    JSON.parse(res.body)["success"] == true
  end

  def app_body(params)
    "Name: #{params[:name]}\nEmail: #{params[:email]}\nGithub Profile URL: #{params[:github_profile_url]}\nWhy work with us? #{params[:cover_letter]}"
  end
end