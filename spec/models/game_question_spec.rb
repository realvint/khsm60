require 'rails_helper'

RSpec.describe GameQuestion, type: :model do
  let(:game_question) { FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  describe 'game status' do
    it 'correct .variants' do
      expect(game_question.variants).to eq({'a' => game_question.question.answer2,
                                            'b' => game_question.question.answer1,
                                            'c' => game_question.question.answer4,
                                            'd' => game_question.question.answer3})
    end

    it 'correct .answer_correct?' do
      expect(game_question.answer_correct?('b')).to be_truthy
    end
  end

  describe '#correct_answer_key' do
    it 'returns correct answer key' do
      expect(game_question.correct_answer_key).to eq 'b'
    end
  end

  describe '#text' do
    it ' returns correct text' do
      expect(game_question.text).to eq(game_question.question.text)
    end
  end

  describe '#level' do
    it 'returns correct level' do
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  describe 'user helpers' do
    context 'helpers' do
      it 'correct audience_help' do
        expect(game_question.help_hash).not_to include(:audience_help)

        game_question.add_audience_help

        expect(game_question.help_hash).to include(:audience_help)

        ah = game_question.help_hash[:audience_help]
        expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
      end
    end
  end
end
