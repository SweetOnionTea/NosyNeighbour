import sounddevice as sd
import sys
import config  # Import your config.py which has MICROPHONE_INDEX

def list_mics_and_select():
    """
    Lists only unique active input devices (based on device name), shows the default microphone,
    and then prompts the user for input. Updates config.MICROPHONE_INDEX or uses default if blank.
    Exits if no devices are found.
    """
    devices = sd.query_devices()  # List all audio devices
    hostapis = sd.query_hostapis()  # List available host APIs
    input_devices = []

    # Filter for active input devices (microphones)
    for idx, dev in enumerate(devices):
        if dev['max_input_channels'] > 0:
            try:
                sd.check_input_settings(device=idx)  # Ensure the device is active
            except Exception:
                continue
            input_devices.append((idx, dev))
    
    if not input_devices:
        print("No active microphone devices found on this machine. Exiting.")
        sys.exit(1)
    
    # Print available input devices with their Host API index
    print("\nAvailable Microphones:")
    for (idx, dev) in input_devices:
        host_api_index = dev['hostapi']
        host_api_name = hostapis[host_api_index]['name']  # Get API name
        print(f"[{idx}] {dev['name']} (Host API Index: {host_api_index}, API: {host_api_name})")

    # Determine if a default input device is set.
    default_input_index = None
    if isinstance(sd.default.device, (list, tuple)) and sd.default.device[0] is not None:
        default_input_index = sd.default.device[0]
        default_device_info = sd.query_devices(default_input_index)
        print(f"\nDefault Microphone: [{default_input_index}] {default_device_info['name']}")

    print("\nPress Enter for the default device, or type a number to pick one.\n")
    user_input = input("Enter device index (or press Enter for default): ").strip()

    if user_input == "":
        print("Using default microphone device.")
        config.MICROPHONE_INDEX = None
    else:
        try:
            chosen_index = int(user_input)
            # Check if chosen_index is one of our input_devices
            valid_indices = [d[0] for d in input_devices]
            if chosen_index in valid_indices:
                config.MICROPHONE_INDEX = chosen_index
                print(f"Microphone set to device index {chosen_index}: {devices[chosen_index]['name']}")
            else:
                print(f"Invalid device index {chosen_index}. Exiting.")
                sys.exit(1)
        except ValueError:
            print("Invalid input. Please enter a number or leave blank for default.")
            sys.exit(1)

if __name__ == "__main__":
    list_mics_and_select()
