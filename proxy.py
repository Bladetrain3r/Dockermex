import socket

# Configuration
LISTEN_HOST = '0.0.0.0'     # Listen on all network interfaces
LISTEN_PORT = 10667         # Port where players will connect (public-facing)
TARGET_HOST = '172.17.0.2'  # Docker container IP running Odamex
TARGET_PORT = 10666         # Port inside the container where Odamex is listening

# Buffer size for UDP packets
BUFFER_SIZE = 4096

# Set up the UDP socket to listen for incoming connections
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((LISTEN_HOST, LISTEN_PORT))

print(f"Listening for UDP connections on {LISTEN_HOST}:{LISTEN_PORT}")
print(f"Forwarding to {TARGET_HOST}:{TARGET_PORT}")

try:
    while True:
        # Receive data from client
        data, addr = sock.recvfrom(BUFFER_SIZE)
        print(f"Received {len(data)} bytes from {addr}")

        # Send data to the target Odamex server
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as forward_sock:
            forward_sock.sendto(data, (TARGET_HOST, TARGET_PORT))

            # Receive response from the Odamex server
            response, _ = forward_sock.recvfrom(BUFFER_SIZE)
            print(f"Forwarded response of {len(response)} bytes back to {addr}")

            # Send the response back to the client
            sock.sendto(response, addr)

except KeyboardInterrupt:
    print("\nShutting down proxy.")
finally:
    sock.close()
