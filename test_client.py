import socket

host = "archvps.us"
port = 7411

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.connect((host, port))
    s.sendall((1).to_bytes(2, "little", signed=False))
    data = s.recv(1024)

print(f"Got {data}")