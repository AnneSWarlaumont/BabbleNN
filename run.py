#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jun 22 12:42:32 2018

@author: awarlau
"""
import sys
sys.path.append('/Users/awarlau/Google Drive/Work/IVOC-NN-Learning/BabbleNN')
import babble_daspnet_reservoir
babble_daspnet_reservoir.sim('Mortimer','/Users/awarlau/Downloads',
                             60,'human',4,False,True)
                             