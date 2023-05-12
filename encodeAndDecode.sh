#!/bin/bash

header=false
version=false

usage() {
  echo "Usage: $0 [-h] [-v]"
}

print_version() {
  echo "Version 2.0.1 Alfa Beta Delta Gamma BP Auchan"
}

print_header(){
  echo "
  
Author           : Piotr Kijoch ( s197226@student.pg.edu.pl )
Created On       : 26.04.2023
Last Modified By : Piotr Kijoch ( s197226@student.pg.edu.pl )
Last Modified On : 10.05.2023
Version          : 2.0.1

Description      : The aim of the project is to create a program that can hide a text message in an image using LSD (Least Significant Digit)

Licensed under GPL (see /usr/share/common-licenses/GPL for more details or contact the Free Software Foundation for a copy)

"
}

execute_program(){
if ! command -v steghide &> /dev/null; then
  echo "Steghide is not installed. Installing now..."
  
  if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install steghide -y
  elif command -v yum &> /dev/null; then
    sudo yum check-update
    sudo yum install steghide -y
  else
    echo "Unable to install steghide. Please install it manually."
    exit 1
  fi
else
  echo "Steghide is already installed."
fi

if ! command -v zenity &> /dev/null; then
  echo "Zenity is not installed. Installing now..."
  
  if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install zenity -y
  elif command -v yum &> /dev/null; then
    sudo yum check-update
    sudo yum install zenity -y
  else
    echo "Unable to install zenity. Please install it manually."
    exit 1
  fi
else
  echo "Zenity is already installed."
fi

if ! command -v dbus-launch &> /dev/null; then
  echo "dbus-x11 is not installed. Installing now..."

  if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install dbus-x11 -y
  elif command -v yum &> /dev/null; then
    sudo yum check-update
    sudo yum install dbus-x11 -y
  else
    echo "Unable to install dbus-x11. Please install it manually."
    exit 1
  fi
else
  echo "dbus-x11 is already installed."
fi

zenity --info --width=400 --height=200 --text="<b><span color='blue' font='20'>Project: Encoding and decoding message from image</span></b>\n\n<span color='red'>The aim of the project is to create a program that can hide a text message in an image using LSD (Least Significant Digit).</span>" --title="Encoding and decoding"

menu=("1.Encode message to an image" "2.Decode message from an image")

WYBOR=$(zenity --list --column=Menu "${menu[@]}")
	WYBOR=${WYBOR:0:1}
	if [[ ${WYBOR} == 1 ]]; then
		while true; do
		  plaintext_file=$(zenity --file-selection --title="Select a message in .txt format" --file-filter="Text files (*.txt) | *.txt")
		  
		  # Check if a file was selected and if it has a .txt extension
		  if [[ -n "$plaintext_file" ]] && [[ "${plaintext_file##*.}" == "txt" ]]; then
		    break  
		  elif [[ -n "$plaintext_file" ]]; then
		    zenity --error --text="Invalid file format. Please select a .txt file."
		   else
		    exit 1 
		  fi
		done

		while true; do
		  cover_image=$(zenity --file-selection --title="Select a cover image" --file-filter="PNG files (*.png) | *.png")
		  
		  # Check if a file was selected and if it has a PNG extension
		  if [[ -n "$cover_image" ]] && [[ "${cover_image##*.}" == "png" ]]; then
		    break
		  elif [[ -n "$cover_image" ]]; then
		    zenity --error --text="Invalid file format. Please select a PNG file."
		  else
		    exit 1
		  fi
		done

		while true; do
		  output_dir=$(zenity --file-selection --title="Select an output directory" --directory)
		  
		  if [[ -n "$output_dir" ]] && [[ -d "$output_dir" ]]; then
		    output_image="$output_dir/output.png"
		    if [[ -e "$output_image" ]]; then
		      if zenity --question --text="The file \"$output_image\" already exists. Do you want to overwrite it?"; then
			rm "$output_image"
			break
		      fi
		    else
		      break
		    fi
		  elif [[ -n "$output_dir" ]]; then
		    zenity --error --text="Invalid directory. Please select an existing directory."
		  else
		    exit 1
		  fi
		done

		passphrase=$(zenity --password --title="Enter Passphrase" --text="Please enter a passphrase:")

		# Encode the plaintext file using AES-256 encryption
		encrypted_data=$(openssl enc -aes-256-cbc -base64 -pass pass:"$passphrase" -pbkdf2 -in "$plaintext_file")

		# Embed the encrypted data in the least significant bits of the cover image
		zenity --info --text="$(steghide --embed --coverfile "$cover_image" --embedfile <(echo "$encrypted_data") --passphrase "$passphrase" -sf "$output_image" 2>&1 | tail -n 1)"
		
		
	elif [[ ${WYBOR} == 2 ]]; then
		while true; do
		  
		  steg_image=$(zenity --file-selection --title="Select a image with message" --file-filter="PNG files (*.png) | *.png")
		  
		  # Check if a file was selected and if it has a PNG extension
		  if [[ -n "$steg_image" ]] && [[ "${steg_image##*.}" == "png" ]]; then
		    break
		  elif [[ -n "$steg_image" ]]; then
		    zenity --error --text="Invalid file format. Please select a PNG file."
		  else
		    exit 1
		  fi
		done

		passphrase=$(zenity --password --title="Enter Passphrase" --text="Please enter a passphrase:")

		# Extract the hidden data from the steganographic image
		if ! steghide extract -sf "$steg_image" -p "$passphrase" -xf - > /dev/null 2>&1; then
		  zenity --error --text="Failed to extract hidden data. Something is wrong with image or passphrase. Stopping program."
		  exit 1
		fi

		hidden_data=$(steghide extract -sf "$steg_image" -p "$passphrase" -xf -)

		# Decrypt the extracted data using AES-256
		plaintext=$(echo "$hidden_data" | openssl enc -aes-256-cbc -d -base64 -pass pass:"$passphrase" -pbkdf2)

		if zenity --question --text="The decrypted message is:\n\n$plaintext\n\nDo you want to save it to a file?" --no-wrap; then
		    filename=$(zenity --file-selection --save --title="Save decrypted message as" --confirm-overwrite)
		    if [[ -n "$filename" ]]; then
		      echo "$plaintext" > "$filename"
		      zenity --info --text="The decrypted message has been saved to:\n$filename"
		    fi
		 fi
	else

		exit 1
	
	fi
}



if ! command -v getopts &> /dev/null; then
  echo "getopts is not installed. Installing now..."
  
  if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install getopts -y
  elif command -v yum &> /dev/null; then
    sudo yum check-update
    sudo yum install getopts -y
  else
    echo "Unable to install getopts. Please install it manually."
    exit 1
  fi
else
  echo "getopts is already installed."
fi

while getopts "hvs" opt; do
  case $opt in
    h)
      header=true
      ;;
    v)
      version=true
      ;;
    s)
      header=true
      version=true
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done


if ! $version && ! $header; then
  execute_program
fi

if $header; then
  print_header
fi

if $version; then
  print_version
fi
