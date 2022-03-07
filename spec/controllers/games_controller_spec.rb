# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # группа тестов для незалогиненного юзера (Анонимус)
  describe 'anon user' do
    context 'when anon user trying to open game page' do
      it 'show alert and redirect to login page' do
        get :show, id: game_w_questions.id

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'when anon user trying to create game' do
      it 'show alert and redirect to login page' do
        post :create

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'when anon user trying to give an answer' do
      it 'show alert and redirect to login page' do
        put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'when anon user trying to take money in game' do
      it 'show alert and redirect to login page' do
        put :take_money, id: game_w_questions.id

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end
  end

  # группа тестов на экшены контроллера, доступных залогиненным юзерам
  describe 'usual user' do
    before(:each) { sign_in user }

    describe "#create" do
      it 'creates game' do
        generate_questions(15)

        post :create
        game = assigns(:game)

        expect(game.finished?).to be_falsey
        expect(game.user).to eq(user)
        expect(response).to redirect_to(game_path(game))
        expect(flash[:notice]).to be
      end
    end

    describe "#show" do
      it '#show game' do
        get :show, id: game_w_questions.id
        game = assigns(:game)
        expect(game.finished?).to be_falsey
        expect(game.user).to eq(user)

        expect(response.status).to eq(200)
        expect(response).to render_template('show')
      end
    end

    describe "#answer" do
      let(:letter) { game_w_questions.current_game_question.correct_answer_key }

      context "when user answer correct" do
        it 'check game and redirect to the second question' do
          put :answer, id: game_w_questions.id, letter: letter
          game = assigns(:game)

          expect(game.finished?).to be_falsey
          expect(game.current_level).to be > 0
          expect(response).to redirect_to(game_path(game))
          expect(flash.empty?).to be_truthy
        end
      end

      context "when user answer incorrect" do
        it 'check game/level and redirect to the user page' do
          wrong_answer_letter = %w[a b c d].reject { |k| k == letter }.sample

          put :answer, id: game_w_questions.id, letter: wrong_answer_letter
          game = assigns(:game)

          expect(game.finished?).to eq true
          expect(game.current_level).to eq 0
          expect(response).to redirect_to(user_path(user))
          expect(flash.empty?).to eq false
        end
      end
    end

    context 'when uses audience help' do
      it 'uses audience help' do
        expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
        expect(game_w_questions.audience_help_used).to be_falsey

        put :help, id: game_w_questions.id, help_type: :audience_help
        game = assigns(:game)

        expect(game.finished?).to be_falsey
        expect(game.audience_help_used).to be_truthy
        expect(game.current_game_question.help_hash[:audience_help]).to be
        expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
        expect(response).to redirect_to(game_path(game))
      end
    end
  end
end
