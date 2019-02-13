#
#   Copyright 2018  SenX S.A.S.
#   Copyright 2019  Nabil BENDAFI <nabil@bendafi.fr>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http:#www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#


require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/warp10"

describe LogStash::Outputs::Warp do

  describe "Configuration" do

    let(:base_config) do
    {
      "warpUri" => "localhost",
      "token" => "a_token"
    }
    end

    describe "validates default configuration" do
      it "should register without errors" do
        output = LogStash::Outputs::Warp.new(base_config)
        expect { output.register }.to_not raise_error
      end

      it "should hold default parameters" do
        output = LogStash::Outputs::Warp.new(base_config)
        output.register
        expect(output.instance_variable_get(:@warpUri)).to eq "localhost"
        expect(output.instance_variable_get(:@warpUri)).to eq "localhost"
        expect(output.instance_variable_get(:@token)).to eq "a_token"
        expect(output.instance_variable_get(:@gtsName)).to eq "logstash"
        expect(output.instance_variable_get(:@labels)).to eq []
        expect(output.instance_variable_get(:@onlyOneValue)).to eq 'false'
        expect(output.instance_variable_get(:@valueKey)).to eq "message"
        expect(output.instance_variable_get(:@flush_size)).to eq 100
        expect(output.instance_variable_get(:@idle_flush_time)).to eq 1
      end
    end

    describe "should fail" do
      it "when missing mandatory field" do
        ['warpUri', 'token'].each do | param |
          expect {LogStash::Outputs::Warp.new(base_config.merge(param => nil))}.to raise_error(LogStash::ConfigurationError)
        end
      end
    end
  end

  describe "Output filter" do

    context "with working configuration" do
      [{
        'name' => "One label",
        'config' => {
          "warpUri" => "localhost", "token" => "a_token", "labels" => ["label1"]
        },
        'event' => {
            "message"=>"Hello World", "@version"=>"1",
            "@timestamp"=>"2019-02-11T23:34:54.076Z", "host" => "a_hostname",
            "label1"=>"foo", "label2"=>"bar", "label3"=>"foobar"
        },
        'expected_str' => "1549928094076000// logstash{source=logstash,label1=foo} '2019-02-11T23:34:54.076Z a_hostname Hello World' \n"
      },
      {
        'name' => "Keep one value",
        'config' => {
          "warpUri" => "localhost", "token" => "a_token", "onlyOneValue" => 'true'
        },
        'event' => {
          "message"=>"Hello World", "@version"=>"1",
          "@timestamp"=>"2019-02-11T23:34:54.076Z", "host" => "a_hostname",
          "label1"=>"foo", "label2"=>"bar", "label3"=>"foobar"
        },
        'expected_str' => "1549928094076000// logstash{source=logstash} 'Hello World' \n"
      },
      {
        'name' => "Keep one value other than message",
        'config' => {
          "warpUri" => "localhost", "token" => "a_token", "onlyOneValue" => 'true', 'valueKey' => 'label2'
        },
        'event' => {
          "message"=>"Hello World", "@version"=>"1",
          "@timestamp"=>"2019-02-11T23:34:54.076Z", "host" => "a_hostname",
          "label1"=>"foo", "label2"=>"bar", "label3"=>"foobar"
        },
        'expected_str' => "1549928094076000// logstash{source=logstash} 'bar' \n"
      },
      {
        'name' => "Multiple labels",
        'config' => {
          "warpUri" => "localhost", "token" => "a_token", "labels" => ["label1", "label3"]
        },
        'event' => {
          "message"=>"Hello World", "@version"=>"1",
          "@timestamp"=>"2019-02-11T23:34:54.076Z", "host" => "a_hostname",
          "label1"=>"foo", "label2"=>"bar", "label3"=>"foobar"
        },
        'expected_str' => "1549928094076000// logstash{source=logstash,label1=foo,label3=foobar} '2019-02-11T23:34:54.076Z a_hostname Hello World' \n"
      },
      {
        'name' => "Geo Time Series name",
        'config' => {
          "warpUri" => "localhost", "token" => "a_token", "gtsName" => "my_gts_name"
        },
        'event' => {
          "message"=>"Hello World", "@version"=>"1",
          "@timestamp"=>"2019-02-11T23:34:54.076Z", "host" => "a_hostname",
          "label1"=>"foo", "label2"=>"bar", "label3"=>"foobar"
        },
        'expected_str' => "1549928094076000// my_gts_name{source=logstash} '2019-02-11T23:34:54.076Z a_hostname Hello World' \n"
      }].each do |test|
        sample(test['name']) do
          output = LogStash::Outputs::Warp.new(test['config'])
          output.register
          expect(output).to receive(:buffer_receive).with(test['expected_str'])
          output.receive(LogStash::Event.new(test['event']))
        end
      end
    end
  end
end
