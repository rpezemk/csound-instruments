import time
from pythonosc import udp_client
from datamodel.Notes import Note
from datamodel.Notes import StepSequencer

# Create an OSC client to send messages to Csound (localhost, port 7400)
client = udp_client.SimpleUDPClient("127.0.0.1", 37707)



notes = [
    Note(0,  70, 0.3, 0, 0),
    Note(12, 70, 0.3, 0, 0),
    Note(7,  70, 0.3, 0, 0),
    Note(10, 70, 0.3, 0, 0),
    Note(5,  70, 0.3, 0, 0),
    Note(7,  70, 0.3, 0, 0),
    Note(3,  70, 0.3, 0, 0),
    Note(7,  70, 0.3, 0, 0),
]


sequencer = StepSequencer(notes, 0.5, lambda list: client.send_message("/notetrigger", list))
while 1 == 1:
    sequencer.playStep()
    time.sleep(0.2)
    