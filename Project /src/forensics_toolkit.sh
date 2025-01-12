#!/bin/bash

# Digital Forensics Toolkit

LOGFILE="logs/forensics_toolkit.log"
CONFIGFILE="config/config.cfg"
declare -A users

# Load configuration
load_config() {
  if [[ -f "$CONFIGFILE" ]]; then
    source "$CONFIGFILE"
  else
    echo "DEFAULT_DEVICE=/dev/sdb1" > "$CONFIGFILE"
    echo "DEFAULT_OUTPUT=forensic_image.img" >> "$CONFIGFILE"
  fi
}

# Function to log messages
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Function to acquire data from a device
acquire_data() {
  read -p "Enter the device to acquire data from (default: $DEFAULT_DEVICE): " device
  device=${device:-$DEFAULT_DEVICE}
  read -p "Enter the output image file name (default: $DEFAULT_OUTPUT): " output_file
  output_file=${output_file:-$DEFAULT_OUTPUT}

  echo "Acquiring data from device $device..."
  if sudo dd if="$device" of="$output_file" bs=512 conv=noerror,sync; then
    log_message "Data acquisition complete from $device to $output_file."
    echo "Data acquisition complete!"
    echo "Generating SHA-256 hash of the acquired data..."
    sudo sha256sum "$output_file" > "$output_file.sha256"
    log_message "SHA-256 hash generated for $output_file."
    echo "SHA-256 hash generated!"
  else
    log_message "Error acquiring data from $device."
    echo "Error acquiring data. Please check the device path."
  fi
}

# Function to analyze the acquired data
analyze_data() {
  read -p "Enter the forensic image file name (default: $DEFAULT_OUTPUT): " input_file
  input_file=${input_file:-$DEFAULT_OUTPUT}

  echo "Analyzing acquired data from $input_file..."
  if sudo autopsy "$input_file"; then
    log_message "Data analysis complete for $input_file."
    echo "Data analysis complete!"
    echo "Generating report..."
    sudo autopsy -report "$input_file" > "reports/${input_file}_report.txt"
    log_message "Report generated for $input_file."
    echo "Report generated!"
  else
    log_message "Error analyzing data from $input_file."
    echo "Error analyzing data. Please check the file path."
  fi
}

# Function to verify data integrity
verify_integrity() {
  read -p "Enter the forensic image file name (default: $DEFAULT_OUTPUT): " input_file
  input_file=${input_file:-$DEFAULT_OUTPUT}

  if [[ -f "$input_file.sha256" ]]; then
    echo "Verifying integrity of $input_file..."
    if sha256sum -c "$input_file.sha256"; then
      echo "Integrity check passed!"
      log_message "Integrity check passed for $input_file."
    else
      echo "Integrity check failed!"
      log_message "Integrity check failed for $input_file."
    fi
  else
    echo "SHA-256 hash file not found. Please acquire data first."
  fi
}

# Function to analyze file types
analyze_file_types() {
  read -p "Enter the forensic image file name (default: $DEFAULT_OUTPUT): " input_file
  input_file=${input_file:-$DEFAULT_OUTPUT}

  echo "Analyzing file types in $input_file..."
  if [ -f "$input_file" ]; then
    file "$input_file" > "reports/${input_file}_file_types.txt"
    echo "File types analysis complete! Results saved in reports/${input_file}_file_types.txt."
    log_message "File types analysis complete for $input_file."
  else
    echo "Forensic image file not found."
  fi
}

# Function to search for keywords in the acquired data
search_keywords() {
  read -p "Enter the forensic image file name (default: $DEFAULT_OUTPUT): " input_file
  input_file=${input_file:-$DEFAULT_OUTPUT}
  read -p "Enter the keyword to search: " keyword

  if [ -f "$input_file" ]; then
    echo "Searching for '$keyword' in $input_file..."
    grep -r "$keyword" "$input_file" > "reports/${input_file}_search_results.txt"
    if [ -s "reports/${input_file}_search_results.txt" ]; then
      echo "Search complete! Results saved in reports/${input_file}_search_results.txt."
      log_message "Search for '$keyword' completed in $input_file."
    else
     
