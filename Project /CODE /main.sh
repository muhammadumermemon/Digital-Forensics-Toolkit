#!/bin/bash

# Digital Forensics Toolkit

LOGFILE="forensics_toolkit.log"
CONFIGFILE="config.cfg"
USERFILE="users.cfg"
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

# Load users from a secure file
load_users() {
  if [[ -f "$USERFILE" ]]; then
    while IFS=':' read -r username password; do
      users["$username"]="$password"
    done < "$USERFILE"
  fi
}

# Function to log messages
log_message() {
  local level="$1"
  local message="$2"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] - $message" >> "$LOGFILE"
}

# Function to acquire data from a device
acquire_data() {
  read -p "Enter the device to acquire data from (default: $DEFAULT_DEVICE): " device
  device=${device:-$DEFAULT_DEVICE}
  read -p "Enter the output image file name (default: $DEFAULT_OUTPUT): " output_file
  output_file=${output_file:-$DEFAULT_OUTPUT}

  echo "Acquiring data from device $device..."
  if sudo dd if="$device" of="$output_file" bs=512 conv=noerror,sync; then
    log_message "INFO" "Data acquisition complete from $device to $output_file."
    echo "Data acquisition complete!"
    echo "Generating SHA-256 hash of the acquired data..."
    sudo sha256sum "$output_file > $output_file.sha256"
    log_message "INFO" "SHA-256 hash generated for $output_file."
    echo "SHA-256 hash generated!"
  else
    log_message "ERROR" "Error acquiring data from $device."
    echo "Error acquiring data. Please check the device path."
  fi
}

# Function to analyze the acquired data
analyze_data() {
  read -p "Enter the forensic image file name (default: $DEFAULT_OUTPUT): " input_file
  input_file=${input_file:-$DEFAULT_OUTPUT}

  echo "Analyzing acquired data from $input_file..."
  if sudo autopsy "$input_file"; then
    log_message "INFO" "Data analysis complete for $input_file."
    echo "Data analysis complete!"
    echo "Generating report..."
    sudo autopsy -report "$input_file" > "${input_file}_report.txt"
    log_message "INFO" "Report generated for $input_file."
    echo "Report generated!"
  else
    log_message "ERROR" "Error analyzing data from $input_file."
    echo "Error analyzing data. Please check the file path."
  fi
}

# Function to verify data integrity
verify_integrity() {
  read -p "Enter the forensic image file name (default: $DEFAULT_OUTPUT): " input_file
  input_file=${input_file:-$DEFAULT_OUTPUT}

  echo "Choose hash algorithm (1: SHA-256, 2: SHA-1, 3: SHA-512): "
  read -p "Enter choice: " hash_choice

  case $hash_choice in
    1) hash_cmd="sha256sum" ;;
    2) hash_cmd="sha1sum" ;;
    3) hash_cmd="sha512sum" ;;
    *) echo "Invalid choice"; return ;;
  esac

  if [[ -f "$input_file.$(echo $hash_cmd | cut -d' ' -f1)" ]]; then
    echo "Verifying integrity of $input_file..."
    if $hash_cmd -c "$input_file.$(echo $hash_cmd | cut -d' ' -f1)"; then
      echo "Integrity check passed!"
      log_message "INFO" "Integrity check passed for $input_file."
    else
      echo "Integrity check failed!"
      log_message "ERROR" "Integrity check failed for $input_file."
    fi
  else
    echo "Hash file not found. Please acquire data first."
  fi
}

# Function to analyze file types
analyze_file_types() {
  read -p "Enter the forensic image file name (default: $DEFAULT_OUTPUT): " input_file
  input_file=${input_file:-$DEFAULT_OUTPUT}

  ```bash
  echo "Analyzing file types in $input_file..."
  file "$input_file" > "${input_file}_file_types.txt"
  log_message "INFO" "File type analysis complete for $input_file."
  echo "File type analysis complete! Results saved in ${input_file}_file_types.txt."
}

# Function to encrypt passwords
encrypt_password() {
  local password="$1"
  echo "$password" | openssl enc -aes-256-cbc -a -salt -pass pass:your_secret_key
}

# Function to decrypt passwords
decrypt_password() {
  local encrypted_password="$1"
  echo "$encrypted_password" | openssl enc -aes-256-cbc -d -a -pass pass:your_secret_key
}

# Change password function
change_password() {
  read -p "Enter username to change password: " username
  if [[ -n "${users[$username]}" ]]; then
    read -s -p "Enter new password (min 8 characters, at least one number and one special character): " new_password
    echo ""
    if [[ ${#new_password} -lt 8 || ! "$new_password" =~ [0-9] || ! "$new_password" =~ [^a-zA-Z0-9] ]]; then
      echo "Password does not meet complexity requirements."
      return
    fi
    users["$username"]="$(echo -n "$new_password" | sha256sum | awk '{print $1}')"
    log_message "INFO" "Password changed for user $username."
    echo "Password changed successfully."
  else
    echo "User  does not exist."
  fi
}

# Function to display help
display_help() {
  echo "Digital Forensics Toolkit Help"
  echo "Usage: ./forensics_toolkit.sh [command]"
  echo "Commands:"
  echo "  acquire   - Acquire data from a device"
  echo "  analyze    - Analyze acquired data"
  echo "  verify     - Verify data integrity"
  echo "  change     - Change user password"
  echo "  help       - Display this help message"
}

# Main script execution
load_config
load_users

case "$1" in
  acquire)
    acquire_data
    ;;
  analyze)
    analyze_data
    ;;
  verify)
    verify_integrity
    ;;
  change)
    change_password
    ;;
  help)
    display_help
    ;;
  *)
    echo "Invalid command. Use 'help' for usage information."
    ;;
esac
LOGFILE="forensics_toolkit.log" CONFIGFILE="config.cfg" USERFILE="users.cfg" declare -A users
load_config() { if [[ -f "$CONFIGFILE" ]]; then source "$CONFIGFILE" else echo "DEFAULT_DEVICE=/dev/sdb1" > "$CONFIGFILE" echo "DEFAULT_OUTPUT=forensic_image.img" >> "$CONFIGFILE" fi }
load_users() { if [[ -f "$USERFILE" ]]; then while IFS=':' read -r username password; do users["$username"]="$password" done < "$USERFILE" fi }





