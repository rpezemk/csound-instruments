import time
from pythonosc import udp_client
from backend.sequencers.Sequencers import Note
from backend.sequencers.Sequencers import StepSequencer
from backend.sequencers.Sequencers import Routing

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

# while True:
#     sequencer.playStep()
#     time.sleep(0.2)


routingInstr = 39
instanceNo = 1
outVolParNo = 1

r = Routing(1, 1)

client.send_message("/mono/createrouting", r.toList())
time.sleep(4)
client.send_message("/mono/setgenmix", [1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1])
    
# while True:
#     client.send_message("/monosynth", [routingInstr, instanceNo, outVolParNo, 0])
#     time.sleep(1)
#     client.send_message("/monosynth", [routingInstr, instanceNo, outVolParNo, 1])
#     time.sleep(1)



