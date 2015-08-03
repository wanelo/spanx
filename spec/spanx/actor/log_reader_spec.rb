require 'spec_helper'
require 'file/tail'
require 'timeout'
require 'thread'
require 'tempfile'
require 'timecop'

describe Spanx::Actor::LogReader do

  subject(:reader) { Spanx::Actor::LogReader.new(files, queue, 1, whitelist) }
  let(:files) { [] }
  let(:queue) { [] }
  let(:whitelist) { nil }
  let(:read_timeout) { 0.1 }

  describe '#read' do
    let(:tempfile) { Tempfile.new('access.log') }
    let!(:file) { Spanx::Actor::File.new(tempfile.path) }
    let(:files) { [ file ] }

    it 'yields each ip in a file as it is written' do
      expect { |b|
        reader_thread = Thread.new do
          begin
            timeout(read_timeout) do
              reader.read(file, &b)
            end
          rescue TimeoutError
          end
        end

        ::File.open(tempfile.path, 'a') do |t|
          t.puts '9.9.9.9 - some stuff'
          t.puts '9.9.9.10 - some other stuff'
          t.puts '9.9.9.9 - whoa moar stuff'
        end

        reader_thread.join
      }.to yield_successive_args('9.9.9.9', '9.9.9.10', '9.9.9.9')
    end

    context 'if a line matches a whitelist' do
      let(:whitelist) { double }

      before do
        allow(whitelist).to receive(:match?).with("9.9.9.9 - some stuff\n").and_return(true)
        allow(whitelist).to receive(:match?).with("9.9.9.10 - some other stuff\n").and_return(false)
      end

      it 'skips that line' do
        expect { |b|
          reader_thread = Thread.new do
            begin
              timeout(read_timeout) do
                reader.read(file, &b)
              end
            rescue TimeoutError
            end
          end

          ::File.open(tempfile.path, 'a') do |t|
            t.puts '9.9.9.9 - some stuff'
            t.puts '9.9.9.10 - some other stuff'
          end

          reader_thread.join
        }.to yield_successive_args('9.9.9.10')
      end
    end
  end

  describe '#run' do
    let!(:file1) { Tempfile.new('log.log') }
    let!(:file2) { Tempfile.new('loge.log') }
    let!(:files) { [file1.path, file2.path] }
    let(:read_timeout) { 0.1 }

    after do
      file1.close
      file2.close
    end

    xit 'pushes ips from each watched file onto queue' do
      Timecop.freeze(Time.at(1409270561))

      runner = Thread.new do
        begin
          timeout(read_timeout) do
            reader.run
            reader.threads.last.join
          end
        rescue TimeoutError
        end
      end

      sleep 1

      file1.puts '1.1.1.1 - everyone loves a log!'
      file2.puts '2.2.2.2 - only some people love a loge'

      runner.join

      expect(queue).to match_array([['1.1.1.1', 1409270561], ['2.2.2.2', 1409270561]])
    end
  end
end
