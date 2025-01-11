#!/bin/bash

# Digital Forensics Toolkit

LOGFILE="forensics_toolkit.log"
CONFIGFILE="config.cfg"
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
    sudo autopsy -report "$input_file" > "${input_file}_report.txt"
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
    file "$input_file" > "${input_file}_file_types.txt"
    echo "File types analysis complete! Results saved in ${input_file}_file_types.txt."
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
    grep -r "$keyword" "$input_file" > "${input_file}_search_results.txt"
    if [ -s "${input_file}_search_results.txt" ]; then
      echo "Search complete! Results saved in ${input_file}_search_results.txt."
      log_message "Search for '$keyword' completed in $input_file."
    else
      echo "No results found for '$keyword'."
      log_message "No results found for '$keyword' in $input_file."
    fi
  else
    echo "Forensic image file not found."
  fi
}

# Function to manage users
manage_users() {
  echo "User  Management"
  echo "1. Add User"
  echo "2. Remove User"
  echo "3. List Users"
  read -p "Choose an option: " option

  case $option in
    1)
      read -p "Enter username to add: " new_user
      users["$new_user"]="$(openssl rand -base64 12)" # Generate a random password
      log_message "User  $new_user added."
      echo "User  $new_user added with a random password."
      ;;
    2)
      read -p "Enter username to remove: " user_to_remove
      unset users["$user_to_remove"]
      log_message "User  $user_to_remove removed."
      echo "User  $user_to_remove removed."
      ;;
    3)
      echo "Current Users:"
      for user in "${!users[@]}"; do
        echo "$user"
      done
      ;;
    *)
      echo "Invalid option."
      ;;
  esac
}

# Function to backup logs and reports
backup_logs() {
  read -p "Enter backup directory (default: ./backup): " backup_dir
  backup_dir=${backup_dir:-./backup}
  mkdir -p "$backup_dir"
  cp "$LOGFILE" "$backup_dir"
  cp *_report.txt "$backup_dir" 2>/dev/null
  echo "Backup completed to $backup_dir."
  log_message "Backup completed to $backup_dir."
}

# Function to restore logs and reports
restore_logs() {
  read -p "Enter backup directory to restore from: " backup_dir
  cp "$backup_dir/$LOGFILE" ./
  cp "$backup_dir/*_report.txt" ./ 2>/dev/null
  echo "Restore completed from $backup_dir."
  log_message "Restore completed from $backup_dir."
}

# Function to validate user input
validate_input() {
  if [ -z "$1" ]; then
    echo "Invalid input. Please try again."
    return 1
  fi
  return 0
}

# Function to authenticate user
authenticate_user() {
  read -p "Enter username: " username
  read -s -p "Enter password: " password
  echo ""
  
  # Check if user exists
  if [[ -n "${users[$username]}" ]]; then
    local hashed_password=$(echo -n "$password" | sha256sum | awk '{print $1}')
    local correct_hashed_password=$(echo -n "${users[$username]}" | sha256sum | awk '{print $1}')

    if [ "$hashed_password" = "$correct_hashed_password" ]; then
      echo "Authentication successful!"
      return 0
    else
      echo "Authentication failed. Please try again."
      return 1
    fi
  else
    echo "User  does not exist."
    return 1
  fi
}

# Load configuration and users
load_config
users["admin"]="$(echo -n 'password123' | sha256sum | awk '{print $1}')" # Default admin user

# Main menu
while true; do
  clear
  echo "Digital Forensics Toolkit"
  echo "---------------------------"
  echo "1. Acquire Data"
  echo "2. Analyze Data"
  echo "3. Verify Data Integrity"
  echo "4. Analyze File Types"
  echo "5. Search Keywords"
  echo "6. Manage Users"
  echo "7. Backup Logs and Reports"
  echo "8. Restore Logs and Reports"
  echo "9. Exit"
  read -p "Enter your choice: " choice

  # Validate user input
  if ! validate_input "$choice"; then
    continue
  fi

  # Authenticate user
  if ! authenticate_user; then
    continue
  fi

  case $choice in
    1)
      acquire_data
      ;;
    2)
      analyze_data
      ;;
    3)
      verify_integrity
      ;;
    4)
      analyze_file_types
      ;;
    5)
      search_keywords
      ;;
    6)
      manage_users
      ;;
    7)
      backup_logs
      ;;
    8)
      restore_logs
      ;;
    9)
      echo "Exiting..."
      log_message "User  exited the toolkit."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please try again."
      ;;
  esac
done
