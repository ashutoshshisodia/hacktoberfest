# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PullRequestService do
  let(:user) { FactoryBot.create(:user) }
  let(:pr_service) { PullRequestService.new(user) }

  describe '.new' do
    context 'valid arguments' do
      it 'returns a UserScoreBoard' do
        expect(pr_service).to_not be(nil)
      end
    end

    context 'invalid arguments' do
      it 'raises an error ' do
        expect { PullRequestService.new(123, 'abc') }
          .to raise_error(ArgumentError)
      end
    end

    context 'no arguments provided' do
      it 'raises an error ' do
        expect { PullRequestService.new }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#all' do
    context 'a new user with no eligible pull requests' do
      before { stub_helper(PR_DATA[:invalid_array]) }

      it 'returns all ineligible prs', vcr: { record: :new_episodes } do
        expect(pr_service.all.count).to eq(4)
      end
    end

    context 'a user with eligible pull requests' do
      before { stub_helper(PR_DATA[:valid_array]) }

      it 'returns all the prs', vcr: { record: :new_episodes } do
        expect(pr_service.all.count).to eq(5)
      end
    end
  end

  describe '#eligible_prs' do
    context 'given an array of 5 pull requests' do
      context 'pull requests with valid dates and valid labels' do
        before { stub_helper(PR_DATA[:valid_array]) }

        it 'filters and returns all 5 PRs', vcr: { record: :new_episodes } do
          expect(pr_service.eligible_prs.length).to eq(5)
        end
      end

      context 'pull requests with 2 invalid dates & valid labels' do
        before { stub_helper(PR_DATA[:array_with_invalid_dates]) }

        it 'filters and returns 2 of the PRs', vcr: { record: :new_episodes } do
          expect(pr_service.eligible_prs.length).to eq(2)
        end
      end

      context '7 pull_requests with valid dates & 2 invalid labels' do
        before { stub_helper(PR_DATA[:array_with_invalid_labels]) }

        it 'filters and returns 5 of the PRs', vcr: { record: :new_episodes } do
          expect(pr_service.eligible_prs.length).to eq(5)
        end
      end

      context 'pull_requests with 4 invalid dates & invalid labels' do
        before { stub_helper(PR_DATA[:invalid_array]) }

        it 'filters & returns an empty array', vcr: { record: :new_episodes } do
          expect(pr_service.eligible_prs.length).to eq(2)
        end
      end
    end
  end

  describe '#scoring_pull_requests' do
    context 'a user with more than 4 eligible pull requests' do
      before { stub_helper(PR_DATA[:valid_array]) }
      it 'returns initial 4 eligible_prs', vcr: { record: :new_episodes } do
        expect(pr_service.scoring_pull_requests.count).to eq(4)
      end
    end

    context 'a user with with 2 eligible pull requests' do
      before { stub_helper(PR_DATA[:valid_array].first(2)) }
      it 'returns only 2 eligible_prs', vcr: { record: :new_episodes } do
        expect(pr_service.scoring_pull_requests.count).to eq(2)
      end
    end
  end

  describe '#non_scoring_pull_requests' do
    context 'a user with more than 4 eligible pull requests' do
      before { stub_helper(PR_DATA[:valid_array]) }
      it 'returns the all PRs minus scoring_pull_requests' do
        expect(pr_service.non_scoring_pull_requests.count).to eq(1)
      end
    end

    context 'a user with with 2 eligible pull requests' do
      before { stub_helper(PR_DATA[:valid_array].first(2)) }
      it 'returns an empty array' do
        expect(pr_service.non_scoring_pull_requests.count).to eq(0)
      end
    end
  end

  def stub_helper(arr_type)
    allow(pr_service)
      .to receive(:github_pull_requests)
      .and_return(pull_request_data(arr_type))
  end
end
