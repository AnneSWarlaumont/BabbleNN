# -*- coding: utf-8 -*-

"""
This is a neural network model of the development of reduplicated canonical
babbling in human infancy.

This is a modification of Izhikevich's (2007 Cerebral Cortex) daspnet.m and of
a previous mode described in Warlaumont (2012, 2013 ICDL-EpiRob) and Warlaumont
& Finnegan (2016 PLOS ONE). Code from those papers was written in MATLAB. This
is a rewriting of the 2016 code in Python.

Vocal tract simulation is performed in Praat (so you must have Praat installed
for this to run).

This version currently only supports human reinforcement. In the MATLAB version
automatic salience-based reinforcement using a modified version of Coath et
al.'s (2009) auditory salience algorithms, written in MATLAB, was also an
option.

Anne S. Warlaumont
warlaumont@ucla.edu or anne.warlaumont@gmail.com
http://www.annewarlaumont.org
For updates, see https://github.com/AnneSWarlaumont/BabbleNN
"""

# Commented out for debugging:
# def sim(simid,path,T,reinforcer,muscscale,yoke,plotOn):
    
"""
Starts or restarts a simulation

simid: a unique identifier for this simulation. Should not contain spaces.
path: path to the directory where your sim data should be saved. No slash
      at the end.
T: the length of time the experiment is to run in seconds. This can be
      changed to a longer or shorter value when a simulation is restarted
reinforcer: the type of reinforcement. For now, must be 'human'.
muscscale: this scales the activity sent to Praat. 4 is the recommended
           value
yoke: indicates whether to run an experiment or a yoked control simulation.
      Set to False to run a regular simulation. Set to True to run a
      yoked control. There must already have been a simulation of the same
      id run, with its data on the path, for the simulation to yoke to.
plotOn: enables plots of several simulation parameters. Set to False to
        disable plots and to True to enable.
Example use: sim('Mortimer','/Users/awarlau/Downloads','7200,'human',4,
                 False,False)
"""

#Temporary, for debugging:
simid = 'Mortimer'
path = '/Users/awarlau/Downloads'
T = 60*60*2
reinforcer = 'relhipos'
muscscale = 4
yoke = False
plotOn = True

import os, numpy as np

DAinc = 1 # amount of dopamine given during reward
sm = 4 # maximum synaptic weight; but note that since synaptic weights are
       # normalized after each update, this isn't the actual max as it was
       # in Izhikevich's code
testint = 1 # number of seconds between vocalizations
M = 100 # number of synapses per neuron
Ne = 800 # number of excitatory reservoir neurons
Ni = 200 # number of inhibitory reservoir neurons
N = Ne + Ni # total number of reservoir neurons
Nout = 100 # number of reservoir output neurons
Nmot = Nout # number of motor neurons
a = np.concatenate((0.02 * np.ones((Ne)), 0.1 * np.ones((Ni))))
    # time scales of the membrane recovery variable for reservoir neurons
d = np.concatenate((8 * np.ones((Ne)), 2 * np.ones((Ni))))
    # membrane recovery variable after-spike shift for reservoir neurons
a_mot = 0.02 * np.ones((Nmot))
        # time scales of the membrane recovery variable for motor neurons
d_mot = 8 * np.ones((Nmot))
        # membrane recovery variable after-spike shift for motor neurons
post = np.floor(np.concatenate(
        (N * np.random.rand(Ne,M), Ne * np.random.rand(Ni,M))))
       # Assign the postsynaptic neurons for each reservoir neuron
post_mot = np.repeat(np.arange(Nmot).transpose(),Nout,0)
           # all output neurons connect to all motor neurons
s = np.concatenate((np.random.rand(Ne,M),-1 * np.random.rand(Ni,M)))
    # synaptic weights within the reservoir
sout = np.random.rand(Nout,Nmot) # synaptic weights from output to motor
sout = sout / np.mean(sout) # normalize sout
sd = np.zeros((Nout,Nmot)) # will store the changes to be made to sout
STDP = np.zeros((Nout,1002))
       # 1000 + 2 milliseconds (assumes 1 ms conduction delays)
v = -65 * np.ones((N)) # reservoir membrane potentials
v_mot = -65 * np.ones((Nmot)) # motor neuron membrane potentials
u = 0.2 * v # reservoir membrane recovery variables
u_mot = 0.2 * v_mot # motor neuron membrane recovery variables
firings = [] # reservoir neuron firings for the current second
outFirings = [] # output neuron firings for the current second
motFirings = [] # motor neuron firings for the current second
DA = 0 # level of dopamine above baseline
muscsmooth = 100 # spike train data smoothed by 100 ms moving average
sec = 0 # current time in the simulation
rew = [] # track when rewards were received
hist_sumsmoothmusc = [] # keep a record of sumsmoothmusc after each second

# Initialize reward policy variables:
if reinforcer == 'relhipos':
    thresh = 0
    temprewhist = [False] * 10 # Keeps track, for up to 10 previous sounds, of
                              # when the threshold for reward was exceeded
    rewcount = 0

# Absolute path where Praat can be found
praatPathmac = '/Applications/Praat.app/Contents/MacOS/Praat'

# Set data directory names:
wavdir = path + '/' + simid + '_Wav'
firingsdir = path + '/' + simid + '_Firings'

# Create data directories:
if os.path.isdir(wavdir) != True:
    os.mkdir(wavdir)
if os.path.isdir(firingsdir) != True:
    os.mkdir(firingsdir)
    
# Begin the simulation!
for sec in range(sec,T):
    
    print('********************************************')
    print('Second ' + str(sec+1) + ' of ' + str(T))
    
    for t in range(0,1000): # millisecond timesteps
        
        # give random input to reservoir and motor neurons:
        I = 13 * (np.random.rand(N) - 0.5)
        I_mot = 13 * (np.random.rand(Nmot) - 0.5)
        
        # get the indices of fired neurons:
        fired = v >= 30
        fired_out = v[0:100] >= 30
        fired_mot = v_mot >= 30
        
        # reset the voltages for the neurons that fired:
        v[fired] = -65
        v_mot[fired_mot] = -65
        
        # individual neuron dynamics:
        u[fired] = u[fired] + d[fired]
        u_mot[fired_mot] = u_mot[fired_mot] + d_mot[fired_mot]
        
        # spike-timing dependent plasticity computations:
        STDP[fired_out,t+1] = 0.1 # record output neuron (i.e. presynaptic
                                  # neuron)spike times.
                                  # t + 1 = t + D assuming max delay = 1
        for k in range(0,Nmot):
            if fired_mot[k]:
                sd[:,k] = sd[:,k] + STDP[:,t] # adjust sd for potentiation-
                                              # eligible synapses
                motFirings.append([t,k]) # update records of when motor
                                         # neurons fired
        for k in range(0,Nout):
            if fired_out[k]:
                outFirings.append([t,k]) # update the records of when
                                         # output neurons fired
        for k in range(0,N):
            if fired[k]:
                firings.append([t,k]) # update the records of when
                                      # reservoir neurons fired
        
        # For any presynaptic neuron that fired, calculate the input
        # current to add to each of its postsynaptic neurons as
        # proportional to the synaptic strength from the presynaptic to
        # the postsynaptic neuron:
        for k in range(0,len(firings)):
            if firings[k][0] > t-1:
                for l in range(0,np.size(post,1)):
                    postnum = int(post[firings[k][1], l])
                    I[postnum] = I[postnum] + s[firings[k][1], l]
        
        # Calculate the currents to add to the motor neurons:
        for k in range(0,len(outFirings)):
            if outFirings[k][0] > t:
                for l in range(0,np.size(post_mot,1)):
                    postnum = int(post_mot[outFirings[k][1], l])
                    I_mot[postnum] = I_mot[postnum] + sout[outFirings[k][1], l]
        
        
        # Individual neuronal dynamics computations (for numerical
        # stability the time step is 0.5 ms)
        v = v + 0.5 * ((0.04 * v + 5) * v + 140 - u + I)
        v = v + 0.5 * ((0.04 * v + 5) * v + 140 - u + I)
        v_mot = v_mot + 0.5 * (
                (0.04 * v_mot + 5) * v_mot + 140 - u_mot + I_mot)
        v_mot = v_mot + 0.5 * (
                (0.04 * v_mot + 5) * v_mot + 140 - u_mot + I_mot)
        u = u + a * (0.2 * v - u)
        u_mot = u_mot + a_mot * (0.2 * v_mot - u_mot)
        
        # Exponential decay of the traces of presynaptic neuron firing
        # with tau = 20 ms
        STDP[:,t + 2] = 0.95 * STDP[:, t + 1]
        
        # Exponential decay of the dopamine concentration over time
        DA = DA * 0.995
        
        # Every 10 ms, modify synaptic weights:
        if (t + 1) % 10 == 0:
            prevsout = sout # for debugging
            sout = np.maximum(0, np.minimum(sm, sout + DA * sd))
                   # change weights but keep values between 0 and sm
            sout = sout / np.mean(sout) # normalize
            sd = 0.99 * sd # The eligibility trace decays exponentially
        
        # Every testint seconds, evaluate the model and maybe give DA
        if (sec + 1) % testint == 0:
            
            # initialize
            if t == 0:
                numfiredmusc1pos = -1 * np.ones(1000)
                numfiredmusc1neg = -1 * np.ones(1000)
                smoothmuscpos = -1 * np.ones(1000 - muscsmooth)
                smoothmuscneg = -1 * np.ones(1000 - muscsmooth)
                smoothmusc = -1 * np.ones(1000 - muscsmooth)
            # Find out which of the agonist and antagonist jaw/lip motor
            # neurons fired this ms:
            numfiredmusc1pos[t] = sum(v_mot[0:int(Nmot/2)] >= 30)
            numfiredmusc1neg[t] = sum(v_mot[int(Nmot/2)-1:Nmot] >= 30)
            if t == 999:
                # Create a moving average of the summed spikes:
                for smootht in range(muscsmooth - 1,999):
                    smoothmuscpos[smootht-muscsmooth+1] = np.mean(
                            numfiredmusc1pos[smootht-muscsmooth+1:smootht])
                    smoothmuscneg[smootht-muscsmooth+1] = np.mean(
                            numfiredmusc1neg[smootht-muscsmooth+1:smootht])
                smoothmusc = muscscale * (smoothmuscpos - smoothmuscneg)
                sumsmoothmusc = sum(smoothmusc)
                hist_sumsmoothmusc.append(sumsmoothmusc)
                if reinforcer == 'human':
                    print('sum(smoothmusc): ' + str(sum(smoothmusc)))
                    decision = input('Reward the model? Press y or n:\n')
                    if decision == 'y':
                        rew.append(sec*1000+t)
                elif reinforcer == 'sumsmoothmusc>25':
                    print('sumsmoothmusc: ' + str(sumsmoothmusc))
                    if sumsmoothmusc > 25:
                        print('rewarded')
                        rew.append(sec*1000+t)
                elif reinforcer == 'relhipos':
                    print('sumsmoothmusc: ' + str(sumsmoothmusc))
                    print('threshold: ' + str(thresh))
                    temprewhist[0:9] = temprewhist[1:10]
                    if sumsmoothmusc > thresh:
                        print('rewarded')
                        rew.append(sec*1000+t)
                        rewcount = rewcount + 1
                        temprewhist[9] = True
                        if sum(temprewhist)>=5:
                            thresh = thresh + 5
                            temprewhist = [False] * 10
                    else:
                        display('not rewarded')
                        temprewhist[9] = False
                    print('temprewhist: ' + str(temprewhist))
                    print('sum(temprewhist): ' + str(sum(temprewhist)))
        
        if sec*1000+t in rew:
            DA = DA + DAinc
    
    # Prepare STDP and firings for the following 1000 ms
    STDP[:,0:1] = STDP[:,1000:1001]
    firings = []
    outFirings = []
    motFirings = []

print(np.mean(np.array(hist_sumsmoothmusc[0:100])))
print(np.mean(np.array(hist_sumsmoothmusc[sec-100:sec])))
print(np.mean(sout[:,0:int(Nmot/2)]))
print(np.mean(sout[:,int(Nmot/2):Nmot]))
            
        