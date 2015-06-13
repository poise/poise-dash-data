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

require 'json'

require 'sinatra'
require 'sinatra/cross_origin'

require_relative './model'


module PoiseDashData
  class Application < Sinatra::Application
    register Sinatra::CrossOrigin

    get '/' do
      content_type :json
      cross_origin
      Model.project_data.to_json
    end

    run! if app_file == $0
  end
end
