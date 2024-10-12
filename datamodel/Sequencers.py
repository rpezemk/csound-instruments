class StepSequencer():
    def __init__(self, sequence :list, period :float, func):
        self.sequence = sequence
        self.period = period
        self.func = func
        self.currIdx = 0
        self.seqLen = len(sequence)
        pass
    
    def playStep(self):
        self.currNote = self.sequence[self.currIdx]
        if self.func is not None:
            self.func(self.currNote.toList())
        self.currIdx += 1
        self.currIdx = self.currIdx % self.seqLen

class Note():
    def __init__(
            self, 
            pitch: int, 
            velocity: int, 
            duration: float, 
            tied: int, 
            ghost: int):
      """this is a step sequencer note model"""
      
      self.pitch = pitch
      self.velocity = velocity
      self.duration = duration
      self.tied = tied
      self.ghost = ghost
      
    def toList(self):
        res = [self.pitch, self.velocity, self.duration, 
               self.tied, self.ghost]        
        return res
      

      
