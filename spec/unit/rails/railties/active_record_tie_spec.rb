# frozen_string_literal: true

require 'airbrake/rails/railties/active_record_tie'

RSpec.describe Airbrake::Rails::Railties::ActiveRecordTie do
  subject(:tie) { described_class.new }

  # +detect_activerecord_adapter+ is private, but it encapsulates the
  # multi-Rails-version adapter lookup that regressed in
  # https://github.com/airbrake/airbrake/issues/1222, so we exercise it
  # directly.
  describe '#detect_activerecord_adapter' do
    let(:detect) { tie.send(:detect_activerecord_adapter, configurations) }

    before { stub_const('Rails', double(env: 'test')) }

    context 'when configurations predates the configs_for API (Rails < 6)' do
      let(:configurations) { { 'test' => { 'adapter' => 'mysql2' } } }

      it 'reads the adapter through the legacy hash API' do
        expect(detect).to eq('mysql2')
      end
    end

    context 'when configs_for yields a Rails 7+ config (responds to #adapter)' do
      let(:configurations) { double('DatabaseConfigurations') }

      before do
        allow(configurations).to receive(:configs_for)
          .with(env_name: 'test')
          .and_return([double('DbConfig', adapter: 'postgresql')])
      end

      it 'returns the adapter reported by the config object' do
        expect(detect).to eq('postgresql')
      end
    end

    context 'when configs_for yields a Rails 6 config (responds to #config)' do
      let(:configurations) { double('DatabaseConfigurations') }

      before do
        allow(configurations).to receive(:configs_for)
          .with(env_name: 'test')
          .and_return([double('DbConfig', config: { 'adapter' => 'sqlite3' })])
      end

      it 'returns the adapter from the config hash' do
        expect(detect).to eq('sqlite3')
      end
    end

    context 'when every database is hidden on Rails 7+ (issue #1222)' do
      let(:configurations) { double('DatabaseConfigurations') }

      before do
        stub_const('ActiveRecord', double(version: Gem::Version.new('7.1.0')))
        allow(configurations).to receive(:configs_for)
          .with(env_name: 'test')
          .and_return([])
        allow(configurations).to receive(:configs_for)
          .with(env_name: 'test', include_hidden: true)
          .and_return([double('DbConfig', adapter: 'trilogy')])
      end

      it 'falls back to hidden configs instead of raising' do
        expect(detect).to eq('trilogy')
      end
    end

    context 'when every database is hidden but ActiveRecord is older than 7.0' do
      let(:configurations) { double('DatabaseConfigurations') }

      before do
        stub_const('ActiveRecord', double(version: Gem::Version.new('6.1.7')))
        allow(configurations).to receive(:configs_for)
          .with(env_name: 'test')
          .and_return([])
      end

      it 'never requests hidden configs (include_hidden is Rails 7+ only)' do
        expect(detect).to be_nil
        expect(configurations).to have_received(:configs_for)
          .with(env_name: 'test')
          .once
      end
    end

    context 'when no configuration resolves on Rails 7+' do
      let(:configurations) { double('DatabaseConfigurations') }

      before do
        stub_const('ActiveRecord', double(version: Gem::Version.new('7.1.0')))
        allow(configurations).to receive(:configs_for)
          .with(env_name: 'test')
          .and_return([])
        allow(configurations).to receive(:configs_for)
          .with(env_name: 'test', include_hidden: true)
          .and_return([])
      end

      it 'returns nil instead of raising' do
        expect(detect).to be_nil
      end
    end
  end
end
