#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'sequel'

require_relative './services/codeclimate'
require_relative './services/codecov'
require_relative './services/gemnasium'
require_relative './services/github'
require_relative './services/travis'


module PoiseDashData
  class Model
    SERVICES = {
      codeclimate: Services::Codeclimate,
      codecov: Services::Codecov,
      gemnasium: Services::Gemnasium,
      github: Services::GitHub,
      travis: Services::Travis,
    }

    def self.db
      @db ||= Sequel.connect(ENV['DATABASE_URL'])
    end

    def self.projects
      @projects ||= (ENV['DASH_PROJECTS'] || '').split(/,/).map(&:strip)
    end

    def self.schema!
      db.create_table(:projects) do
        primary_key :id
        String :name
        String :service
        String :data
        Time :ts
        unique [:name, :service]
      end
    end

    def self.project_data
      db[:projects].inject({}) do |memo, row|
        if projects.include?(row[:name])
          memo[row[:name]] ||= {}
          memo[row[:name]][row[:service]] = JSON.parse(row[:data])
        end
        memo
      end
    end

    def self.update!
      overall_start = Time.now
      projects.each do |project|
        $stdout.write("Updating #{project}")
        start = Time.now
        SERVICES.map do |service, service_impl|
          Thread.new do
            self.update_service!(project, service.to_s, service_impl)
          end
        end.each do |thread|
          thread.join
        end
        puts(" (#{Time.now - start}s)")
      end
      puts("Overall #{Time.now - overall_start}s")
    end

    def self.update_service!(project, service, service_impl)
      filter = {
        name: project,
        service: service,
      }
      begin
        data = service_impl.update(db, project).to_json
      rescue StandardError => ex
        puts "\nError while updating #{project} #{service}: #{ex}"
        return
      end
      values = {
        data: data,
        ts: Time.now,
      }
      if db[:projects].filter(filter).update(values) == 0
        db[:projects].insert(values.merge(filter))
      end
    end
  end
end
