import time
from pythonosc import udp_client
from datamodel.Sequencers import Note
from datamodel.Sequencers import StepSequencer

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

sequencer = StepSequencer(notes, 0.5, lambda list: client.send_message("/notetrigger", list), 0)

while True:
    sequencer.playStep()
    time.sleep(0.2)
    