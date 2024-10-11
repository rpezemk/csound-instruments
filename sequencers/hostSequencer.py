from pythonosc import udp_client
import time

# Create an OSC client to send messages to Csound (localhost, port 7400)
client = udp_client.SimpleUDPClient("127.0.0.1", 37707)

notes = [
    [0,  70, 0.3, 0, 0,],
    [12, 70, 0.3, 0, 0,],
    [7,  70, 0.3, 0, 0,],
    [10, 70, 0.3, 0, 0,],
    [5,  70, 0.3, 0, 0,],
    [7,  70, 0.3, 0, 0,],
    [3,  70, 0.3, 0, 0,],
    [7,  70, 0.3, 0, 0,],
]
nNotes = len(notes)
idx = -1
while 1 == 1:
    if idx == nNotes:
        idx = 0
    client.send_message("/notetrigger", notes[idx])  # Change frequency to 523.25 Hz (C5) 
    time.sleep(0.2)
    idx += 1;