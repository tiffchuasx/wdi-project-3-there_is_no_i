class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token

  # enable :sessions

# params[:From] -> gets the sender's number '+6587427184'
# params[:Body] -> gets the sender's message
  def receive
    # we can keep message counts in sesssion to check if it's the first message to maintain a conversation
    # session["counter"] ||= 0
    # sms_count = session["counter"]
    # if sms_count == 0
    #   # do something
    # else
    #   # do something else
    # end
    # session["counter"] += 1

    from = params[:From]
    body = params[:Body]
    @user = User.find(phone: from)
    if @user.count > 0
        message = "Hey #{@user[0].name}! Thanks for sending #{body}!"
    else
        message "Hmm... Thanks for the message, but you're a complete stranger to us!"
    end
    twiml = Twilio::TwiML::Response.new do |r|
      r.Message message
    end
    twiml.text
  end
end