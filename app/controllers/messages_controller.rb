require 'http'

class MessagesController < ApplicationController
  def index
    @messages = Message.all
    @message = Message.new
  end

  def create
    @message = Message.new(message_params)
    response = openai_api_call(@message.prompt)

    if response.status.success?
      response_body = JSON.parse(response.body)
      @message.response = response_body['choices'][0]['message']['content']
      if @message.save
        render json: { response: @message.response }
      else
        render json: { error: @message.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    else
      render json: { error: 'APIリクエストが失敗しました' }, status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:prompt)
  end

  def openai_api_call(prompt)
    HTTP.post(
      'https://api.openai.com/v1/chat/completions',
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{ENV['OPENAI_API_KEY']}"
      },
      json: {
        model: "gpt-5-mini",
        messages: [{ role: "user", content: prompt }]
      }
    )
  end
end
