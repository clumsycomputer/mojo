import subprocess

def capture_auth_code():
  """
  Captures the stdout of the modular auth command and extracts the 4-character alphanumeric code.

  Returns:
      str: The extracted 4-character alphanumeric code or None if not found.
  """
  # Replace 'modular_auth' with the actual command
  try:
    process = subprocess.Popen(['modular_auth'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, err = process.communicate()
    output = output.decode("utf-8")
  except Exception as e:
    print(f"Error running modular_auth: {e}")
    return None

  # Extract the code using regular expression
  import re
  match = re.search(r"Verify using the code: ([\w]{4}-[\w]{4})", output)
  if match:
    return match.group(1)
  else:
    print("Code not found in output")
    return None

if __name__ == "__main__":
  extracted_code = capture_auth_code()
  if extracted_code:
    print(f"Extracted code: {extracted_code}")
  else:
    print("Failed to extract code")
