import sys
import os
import re
import string
import sys

from os import listdir
from os.path import isfile, join

def printUsage():
    print('Usage: movpkgmerge.py (-r) <target directory>')
    print('-r: Recursively convert all .movpkg folders inside the target directory.')
    print('If not using -r, target directory should be the movpkg to convert')

def isMp4(trackPath):
    trackName = os.path.basename(os.path.normpath(trackPath))
    trackInfoPath = join(trackPath, trackName) + '.m3u8'
    trackInfoFile = open(trackInfoPath, "r")
    lines = trackInfoFile.readlines()
    trackInfoFile.close()
    for line in lines:
        if '#EXT-X-MAP:URI=' in line:
            return 1
    return 0

def atoi(text):
    return int(text) if text.isdigit() else text

def natural_keys(text):
    return [ atoi(c) for c in re.split(r'(\d+)', text) ]
    
def mergeMovPkg(pathToMovPkg):
    trackDirectories = [f for f in listdir(pathToMovPkg) if f != 'Data' and f != 'boot.xml' and f != 'root.xml']

    for trackDirectory in trackDirectories:
        trackDirectoryPath = join(pathToMovPkg,trackDirectory)
        trackIsMp4 = isMp4(trackDirectoryPath)
        trackNum = trackDirectory.split('-')[0]
        
        extension = 'ts'
        if trackIsMp4:
            extension = 'mp4'

        if len(trackDirectories) > 1:
            exportFilePath = os.path.splitext(pathToMovPkg)[0] + '_track' + trackNum + '.' + extension
        else:
            exportFilePath = os.path.splitext(pathToMovPkg)[0] + '.' + extension
        
        if os.path.exists(exportFilePath):
            print("%s already exists, skipping" % os.path.basename(os.path.normpath(exportFilePath)))
            continue
        exportFile = open(exportFilePath,'ab+')
        
        trackFragments = [f for f in listdir(trackDirectoryPath) if str.endswith(f, '.frag') or str.endswith(f, '.initfrag')]
        trackFragments.sort(key=natural_keys)
        for fragmentFileName in trackFragments:
            fragmentFile = open(join(trackDirectoryPath, fragmentFileName), 'rb')
            exportFile.write(fragmentFile.read())
            fragmentFile.close()
        exportFile.close()
        print('Merged track %s of %s to %s' %(trackDirectory, os.path.basename(os.path.normpath(pathToMovPkg)), os.path.basename(os.path.normpath(exportFilePath))))

recursive = 0
for arg in sys.argv:
    if '-r' in arg:
        recursive = 1

if len(sys.argv) < 2 or len(sys.argv) > 2 + recursive:
    printUsage()
    sys.exit(0)
    
specifiedPath = sys.argv[-1]
if not os.path.exists(specifiedPath):
    print('Error: No directory at path %s' % specifiedPath)
    sys.exit(1)

if recursive:
    movPkgNames = [f for f in listdir(specifiedPath) if str.endswith(f, '.movpkg')]
    for movPkgName in movPkgNames:
        movPkgPath = join(specifiedPath, movPkgName)
        mergeMovPkg(movPkgPath)
else:
    mergeMovPkg(specifiedPath)