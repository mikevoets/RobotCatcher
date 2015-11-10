module RobotCatcher
  module Modals
    extend ActiveSupport::Concern

    module ClassMethods
      def rc_validate(*params)
        @@rc_params = params

        self.class_eval do
          def robot?(params, ip)
            timestamp = params["timestamp"]

            if timestamp.nil? or \
              timestamp.to_i < Time.now.to_i - 300 or timestamp.to_i > Time.now.to_i
              return true
            end

            spinner = params["spinner"]

            hash_spinner = Digest::MD5.hexdigest(timestamp + ip.to_s + "robotcatcher")

            if spinner.nil? or spinner != hash_spinner
              return true
            end

            object_name   = self.class.name.downcase
            object_params = params.include?(object_name) && \
              params[object_name].is_a?(Hash) ? params[object_name] : params
            
            to_be_validated = object_params.select {|k,v| @@rc_params.include? k.to_sym}

            if to_be_validated.length != @@rc_params.length
              return true
            end
            
            to_be_validated.each do |k, v|
              hash = Digest::MD5.hexdigest(k.to_s + hash_spinner + "robotcatcher")
              if !params.include? hash or !params[hash].empty?
                return true
              end
            end
            
            false
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, RobotCatcher::Modals
