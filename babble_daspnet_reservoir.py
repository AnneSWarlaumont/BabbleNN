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

def sim(simid,path,T,reinforcer,muscscale,yoke,plotOn):
    
    """
    Starts or restarts a simulation
    
    simid: a unique identifier for this simulation. Should not contain spaces.
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
    Example use: sim('Mortimer','~/Downloads/','7200,'human',4,False,False)
    """
    
    import os, numpy as np
    
    DAinc = 1 # amount of dopamine given during reward
    sm = 4 # maximum synaptic weight
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
    post = np.ceil(np.concatenate(
            (N * np.random.rand(Ne,M), Ne * np.random.rand(Ni,M))))
           # Assign the postsynaptic neurons for each reservoir neuron
    post_mot = np.repeat(np.arange(Nmot)[:,np.newaxis],Nout,1)
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
    firings = np.array([-1, 0])
              # reservoir neuron firings for the current second; 1 s delays
    outFirings = np.array([-1, 0])
                 # output neuron firings for the current second; 1 s delays
    motFirings = np.array([-1, 0])
                 # motor neuron firings for the current second; 1 s delays
    DA = 0 # level of dopamine above baseline
    muscsmooth = 100 # spike train data smoothed by 100 ms moving average
    sec = 0 # current time in the simulation
    rew = np.array([]) # track when rewards were received

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
        