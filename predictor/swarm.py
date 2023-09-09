# export NUPIC=/media/ricardo/extra/opt/nupic/
# export NTA_CONF_PATH=/home/ricardo/.local/lib/python2.7/site-packages/nupic-0.1.0-py2.7.egg/nupic/support/

import os
import pprint

# add logging to output errors to stdout
import logging
logging.basicConfig()

from nupic.swarming import permutations_runner
from swarm_description import SWARM_DESCRIPTION

INPUT_FILE = "rec-center-hourly.csv"

def modelParamsToString(modelParams):
    pp = pprint.PrettyPrinter(indent=2)
    return pp.pformat(modelParams)
# modelParamsToString

def writeModelParamsToFile(modelParams, name):
    cleanName = name.replace(" ", "_").replace("-", "_")
    paramsName = "%s_model_params.py" % cleanName
    outDir = os.path.join(os.getcwd(), 'model_params')
    if not os.path.isdir(outDir):
        os.mkdir(outDir)
    outPath = os.path.join(os.getcwd(), 'model_params', paramsName)
    with open(outPath, "wb") as outFile:
        modelParamsString = modelParamsToString(modelParams)
        outFile.write("MODEL_PARAMS = \\\n%s" % modelParamsString)
    return outPath
# writeModelParamsToFile

def swarmForBestModelParams(swarmConfig, name, maxWorkers=4):
    outputLabel = name
    permWorkDir = os.path.abspath('swarm')
    if not os.path.exists(permWorkDir):
        os.mkdir(permWorkDir)
    modelParams = permutations_runner.runWithConfig(
        swarmConfig,
        {"maxWorkers": maxWorkers, "overwrite": True},
        outputLabel=outputLabel,
        outDir=permWorkDir,
        permWorkDir=permWorkDir,
        verbosity=0
    )
    modelParamsFile = writeModelParamsToFile(modelParams, name)
    return modelParamsFile
# swarmForBestModelParams

def printSwarmSizeWarning(size):
    if size is "small":
        print "= THIS IS A DEBUG SWARM. DON'T EXPECT YOUR MODEL RESULTS TO BE GOOD."
    elif size is "medium":
        print "= Medium swarm. Sit back and relax, this could take awhile."
    else:
        print "= LARGE SWARM! Might as well load up the Star Wars Trilogy."
# printSwarmSizeWarning

def swarm(filePath):
    name = os.path.splitext(os.path.basename(filePath))[0]
    print "================================================="
    print "= Swarming on %s data..." % name
    printSwarmSizeWarning(SWARM_DESCRIPTION["swarmSize"])
    print "================================================="
    modelParams = swarmForBestModelParams(SWARM_DESCRIPTION, name)
    print "\nWrote the following model param files:"
    print "\t%s" % modelParams
# swarm

if __name__ == "__main__":
    swarm(INPUT_FILE)
# __main__
