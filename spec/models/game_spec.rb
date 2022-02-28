require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      generate_questions(60)

      game = nil
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15).and(
          change(Question, :count).by(0)
        )
      )
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  context 'game mechanics' do
    it 'answer correct continues game' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level + 1)
      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)

      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it 'take_money! finishes game' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      game_w_questions.take_money!

      prize = game_w_questions.prize

      expect(prize).to be_positive
      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize
    end
  end

  context '.status' do
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  describe '#current_game_question' do
    it 'should returns correct game question' do
      expect(game_w_questions.current_game_question).to eq game_w_questions.game_questions[0]
    end
  end

  describe '#previous_level' do
    it 'should returns correct games previous level ' do
      game_w_questions.current_level = 7
      expect(game_w_questions.previous_level).to eq game_w_questions.current_level - 1
    end
  end

  describe '#answer_current_question!' do
    let(:level) { game_w_questions.current_level }
    let(:correct_answer_key) { game_w_questions.game_questions[level].correct_answer_key }

    context 'when answer is correct' do
      before do
        game_w_questions.answer_current_question!(correct_answer_key)
      end

      it 'should returns game finished false if correct answer' do
        expect(game_w_questions.finished?).to eq false
      end

      it 'should returns status in_progress' do
        expect(game_w_questions.status).to eq :in_progress
      end
    end

    context 'when answer is not correct' do
      before do
        answer_correct = game_w_questions.current_game_question.correct_answer_key
        wrong_answer_key = %w[a b c d].reject { |k| k == answer_correct }.sample
        game_w_questions.answer_current_question!(wrong_answer_key)
      end

      it 'should returns game failed if not correct answer' do
        expect(game_w_questions.is_failed).to eq true
      end

      it 'should returns status fail' do
        expect(game_w_questions.status).to eq :fail
      end
    end

    context 'when current question is last' do
      it 'should returns status won if answer to last question is true' do
        game_w_questions.current_level = 14
        game_w_questions.answer_current_question!(correct_answer_key)

        expect(game_w_questions.status).to eq(:won)
      end
    end

    context 'when the correct answer is given after time' do
      before do
        game_w_questions.created_at = Game::TIME_LIMIT.ago
        game_w_questions.answer_current_question!(correct_answer_key)
      end

      it 'should returns game is finished if time is out' do
        expect(game_w_questions.finished?).to eq true
      end

      it 'should returns status timeout' do
        expect(game_w_questions.status).to eq :timeout
      end
    end
  end
end
