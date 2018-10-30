require "IAS/Nagios/GeistWatchdogA/version"

require 'deep_merge'
require 'json'
require 'erb'
require 'pp'


module IAS
  module Nagios
    module GeistWatchdogA
def GeistWatchdogA.marshal_copy(copy_me)
        return Marshal.load(Marshal.dump(copy_me))
end

# This works similar to hash.merge except it creates a 
# copy of all of the data before assigining it back.
def GeistWatchdogA.derp_copy(
	data_b,
	data_a,
	path_b = [],
	path_a = []
)
	
	target_a = data_a
	target_b = data_b
	
	path_a.each { |x|
		if ! target_a.key?(x)
			target_a[x] = {}
		end
		target_a = target_a[x]
	}
	
	path_b.each { |x|
		if ! target_b.key?
			target_b[x] = {}
		end
		target_b = target_b[x]
	}
	
	# puts "Target b"
	# puts target_b.pretty_inspect.gsub(/^/, "#")

	# puts "Target a"
	# puts target_a.pretty_inspect.gsub(/^/, "#")
	
	# exit
	
	source_a = marshal_copy(target_a)
	source_b = marshal_copy(target_b)
	target_a.deep_merge!(
		source_b.deep_merge!(
			source_a
	))
	
	return data_a
end

def GeistWatchdogA.get_watchdog_sensor_structures(
	nagios_checks,
	alert_defaults,
	sensor_data_structure,
	settings = {}

)

	default_sensor_mapping = {}
	
	sensor_data_structure['sensors'].each_pair do | sensor_type, sensor_type_data |
		default_sensor_mapping[sensor_type] = {}
		sensor_type_data['oids'].each_pair do | measurement_name, oid |
			
			if (alert_defaults[measurement_name].nil?)
				next
			end
								
			default_sensor_mapping[sensor_type]['fields'] ||= {}
			
			if (settings['use_dummy'])
				dummy_check = marshal_copy(nagios_checks['check_dummy'])
				dummy_params = marshal_copy(alert_defaults[measurement_name]['dummy_params'])
				dummy_check.merge!(dummy_params)
					
				default_sensor_mapping[sensor_type]['fields'][measurement_name] = dummy_check

			else
			default_sensor_mapping[sensor_type]['fields'][measurement_name] = \
				marshal_copy(nagios_checks[alert_defaults[measurement_name]['nagios_check']])
			end
		end
	end
		
	watchdog_sensor_structure = {
		'sensor_data_structure' => sensor_data_structure,
		'default_sensor_mapping' => default_sensor_mapping,
	}

	return watchdog_sensor_structure

end

def GeistWatchdogA.copy_default_sensor_settings(watchdog_15_hosts, watchdog_sensor_structure)
	# '1' => marshal_copy(default_airFlowSensor_settings),
	
	watchdog_15_hosts.each do | host_data |
		host_data['wanted_sensor_data'].each_pair do | sensor_type , sensor_data |
		
			# puts "Sensor data:"
			# puts sensor_data.pretty_inspect.gsub(/^/, "#")
			
			sensor_data.each_pair do | snmp_sensor_index, individual_sensor_data |
				
				# puts watchdog_sensor_structure['default_sensor_mapping'].pretty_inspect()
				# puts "Sensor type:"
				# puts sensor_type
				# exit
				
				data_to_copy = watchdog_sensor_structure['default_sensor_mapping'][sensor_type]

				# puts "Data to copy:"
				# puts data_to_copy.pretty_inspect.gsub(/^/, "#")
				# puts "-----------"
				# puts "Individual sensor data:"
				# puts individual_sensor_data.pretty_inspect.gsub(/^/,"#")
				individual_sensor_data = derp_copy(data_to_copy, individual_sensor_data)
				
				individual_sensor_data['fields'].each_pair do | field_name , field_data |
					if (field_data.nil?)
						next
					end	
					field_data['oid'] = [
						watchdog_sensor_structure['sensor_data_structure']['sensors'][sensor_type]['base_oid'],
						watchdog_sensor_structure['sensor_data_structure']['sensors'][sensor_type]['oids'][field_name],
						snmp_sensor_index,
					].join('.')
					
					field_data['snmp_community'] = host_data['snmp_community']
				end
			end
		end
	end
end

def GeistWatchdogA.add_description_to_watchdogs (watchdog_15_hosts)
	# This is where we merge the descriptions with the host definitions.
	wanted_description_fields = ['name']
	count=0
	watchdog_15_hosts.each do | host_data |
		host_data['wanted_sensor_data'].each_pair do | sensor_type , sensor_data |
			sensor_data.each_pair do | snmp_sensor_index, individual_sensor_data |
				individual_sensor_data['fields'].each_pair do | field_name , field_data |
					if (field_data.nil?)
						next
					end
					count = count + 1

					descriptive_components = host_data['wanted_sensor_data'][sensor_type][snmp_sensor_index]
					
					
					wanted_description_values = []

					wanted_description_fields.each do | wanted_field_name |
						wanted_description_values.push descriptive_components[wanted_field_name]
					end

					wanted_description_values.push(field_name)

					wanted_description_values.push(sensor_type + ' ' + snmp_sensor_index)
			
					field_data['auto_description'] = wanted_description_values.join(' -- ')
				end
			end
		end
	end
end

def GeistWatchdogA.set_default_host_configuration(
	watchdog_15_hosts,
	default_host_configuration
)

	for index in (0...watchdog_15_hosts.length)
		merge_data = marshal_copy(default_host_configuration)
		watchdog_15_hosts[index] = merge_data.merge!(watchdog_15_hosts[index])
	end

end

def GeistWatchdogA.set_default_host_checks(
	watchdog_15_hosts,
	nagios_checks,
	alert_defaults,
	settings
)
	watchdog_15_hosts.each do | watchdog_host |
	
		watchdog_host['default_check_names'].each do | check_name |
			watchdog_host['default_checks'] ||= {}

			if (settings['use_dummy'])
				# print "CHeck name: " + check_name + "\n"
				# puts nagios_checks.pretty_inspect()
				# puts alert_defaults.pretty_inspect()
				dummy_check = marshal_copy(nagios_checks['check_dummy'])
				dummy_params = marshal_copy(alert_defaults[check_name]['dummy_params'])
				dummy_check.merge!(dummy_params)
					
				watchdog_host['default_checks'][check_name] = dummy_check

			else
			watchdog_host['default_checks'][check_name] = \
				marshal_copy(nagios_checks[alert_defaults[check_name]['nagios_check']])
			end

		end
	
	end
	
	# puts watchdog_15_hosts.pretty_inspect()
	# exit
end

def GeistWatchdogA.generic_nagios_parameter_output(data)
	data_lines = []
	data.each_pair do | name, data_entry |
		if (data_entry.is_a?(Array))
			data_lines.push(
				sprintf("\t%s\t%s",
					name,
					data_entry.join(",\\\n\t\t")
				)
			)
		elsif (data_entry.is_a?(String))
			data_lines.push(
				sprintf("\t%s\t%s",
					name,
					data_entry,
				)
			)
		elsif (data_entry.is_a?(Fixnum))
			data_lines.push(
				sprintf("\t%s\t%d",
					name,
					data_entry,
				)
			)		
		else
			data_lines.push(
				sprintf("# UNHANDLED TYPE: %s %s",
					name,
					data_entry.class,
				)
			)
		end
	end
	return data_lines.join("\n")
end

def GeistWatchdogA.do_main_processing(
	settings,
	nagios_checks,
	alert_defaults,
	default_host_configuration,
	watchdog_15_hosts,
	sensor_data_structure
)

	watchdog_sensor_structure = get_watchdog_sensor_structures(
		nagios_checks,
		alert_defaults,
		sensor_data_structure,
		settings,
	)


	if (settings['use_dummy'])
		default_host_configuration['nagios_host_use'] = 'IAS_nagios_dev_blackhole'
		default_host_configuration['nagios_service_use'] = 'IAS_nagios_dev_blackhole'
	end

	set_default_host_configuration(watchdog_15_hosts, default_host_configuration)

	set_default_host_checks(watchdog_15_hosts, nagios_checks, alert_defaults, settings)


	copy_default_sensor_settings(watchdog_15_hosts, watchdog_sensor_structure)
	add_description_to_watchdogs(watchdog_15_hosts)

	# puts watchdog_15_hosts.pretty_inspect.gsub(/^/, "#")

	erb_file_name = File.expand_path(File.dirname(__FILE__)) + "/GeistWatchdogA/watchdog_15.erb"

	erb = ERB.new(File.read(erb_file_name))

	return erb.result(binding)

end


    end
  end
end
