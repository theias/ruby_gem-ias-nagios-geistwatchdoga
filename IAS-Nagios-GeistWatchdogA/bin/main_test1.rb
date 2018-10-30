#!/usr/bin/env ruby

require "bundler/setup"
require "IAS/Nagios/GeistWatchdogA"

require 'json'

conf_dir = File.dirname(__FILE__)+'/../etc/'

examples_dir='dev_watchdog_data/'

settings = {
	'use_dummy' => true,
}

nagios_checks = JSON.parse(File.read(conf_dir+examples_dir+'nagios_checks.json'))
alert_defaults = JSON.parse(File.read(conf_dir+examples_dir+'alert_defaults.json'))
default_host_configuration=JSON.parse(File.read(conf_dir+examples_dir+'laboratory_host_defaults.json'))
watchdog_sensor_structure=JSON.parse(File.read(conf_dir+examples_dir+'watchdog_sensor_structure.json'))


watchdog_15_hosts = [
	JSON.parse(File.read(conf_dir+examples_dir+'labwatchdog1.example.com.json')),
]

erb_result = IAS::Nagios::GeistWatchdogA::do_main_processing(
	settings,
	nagios_checks,
	alert_defaults,
	default_host_configuration,
	watchdog_15_hosts,
	watchdog_sensor_structure,
)

print erb_result+"\n"
