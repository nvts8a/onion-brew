require 'json'
DEBUG = true

# Logger entry point
def main

  log ">> Read w1_slave file contents"
  w1_slave = File.readlines(config[:temp][:output])

  log ">> Parse w1_slave file contest to be logged"
  parsed_w1_slave = parse_w1(w1_slave)

  log ">> Construct status object"
  status = construct_status([parsed_w1_slave])

  log ">> Write status object as JSON to log"
  write(status)
end

# Parse the w1 file output into usable values
def parse_w1(file)
  log ">>> Parsing w1_slave file: #{file}"
  
  # The temperature sensor is active and running if the crc value is not "00"
  status = file[0].split("=")[1][0,2]
  is_active = status != "00"
  log ">>> is_active: #{is_active}"

  # The temp is the value to the right of the "=" sign, convert to float
  #   It then must be divided by 1000 to get the value in Celsius
  temp = file[1].split("=")[1].to_f
  temp /= 1000
  log ">>> temp: #{temp}"

  {
    is_temp_active: is_active,
    temp: temp
  }
end

# Method to turn any array of hashes into a merged single status hash
def construct_status(data_array)
  status = {}

  data_array.each do |data|
    status.merge!(data)
  end

  status
end

# Constructs the log entry and appends the status to the log
def write(status)
  time = Time.new
  filename = "#{config[:log][:suffix]}-#{time.strftime("%Y-%m-%d")}"
  File.open("#{config[:log][:dir]}/#{filename}", "a") { |f| f.puts "#{time}|#{status.to_json}\r" }
end

# Helper method that loads and stores config, only references the script portion
def config
  @config ||= JSON.parse(File.open("/www/apps/onion-brew/app.json", "rb").read, symbolize_names: true)
  log ">>> Config called: #{@config}"
  @config[:scriptConfig]
end

# Just a handy way of debugging when testing on the Omega, set DEBUG constant to true
#   You can literally delete these if they're confusing, set DEBUG to false to mute
def log(message)
  puts message if DEBUG
end

log "> Starting onion-brew-logger"
main
log "> Finished running onion-brew-logger"
