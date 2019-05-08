#!/usr/bin/python3

#Script to migrate Terraform state files in s3

import argparse
import re
from boto3 import client
from boto3 import resource

class StateFile(object):
    def __init__(self, oldPath):
        self.oldPath = oldPath
        self.newPath = None
        self.copied = None

    def setNewStatePath(self, replaceArgs):
        """
        Builds the new statefile path by breaking up the old path and replacing the relevant parts
        @param replaceArgs (dict) List of keys to replace in the statefile
        """
        regex = re.compile('env:/(?P<env>.*)/account=(?P<account>[0-9]+)/'
                '(app=(?P<app>.*?)/)?(branch=(?P<branch>.*?)/)?(brand=(?P<brand>.*?)/)?'
                'region=(?P<region>.*)/stack=(?P<stack>.*)/stack')
        try:
          brokenDownState = re.search(regex, self.oldPath).groupdict()
        except AttributeError:
          return
        for key, value in replaceArgs.items():
          brokenDownState[key] = value
        newPath = ('env:/%s' % brokenDownState.pop('env'))
        for key, value in sorted(brokenDownState.items()):
          if value is not None:
            newPath = ('%s/%s=%s' % (newPath, key, value))
        newPath = ('%s/stack.tfstate' % newPath)
        if newPath == self.oldPath:
          return
        self.newPath = newPath

    def copy(self, bucket):
        """
        Copy the the statefile to a new path in the S3 bucket
        @param bucket (string) the name of the bucket that contains the statefile
        """
        if self.newPath is None:
          self.copied = False
          return
        copySource = {'Bucket': bucket,
                       'Key': self.oldPath}
        try:
          resource('s3').meta.client.copy(copySource, bucket, self.newPath)
        except:
          self.copied = False

class NameValuePair(argparse.Action):
    """
    argparse action that accepts up to seven key=value pairs and breaks them
    into a dictonary
    """

    def __call__(self, parser, namespace, values, option_string=None):
      args = {}
      accepted_keys = ['env', 'account', 'app', 'branch', 'brand', 'region', 'stack']
      for arg in values:
        key, value = arg.split('=')
        if key not in accepted_keys:
          raise ValueError('%s is not an accepted key' % key)
        args[key] = value
      setattr(namespace, self.dest, args)

def fetch_statefiles(bucket, region, startAfter):
    """
    Fetches up to a 1000 keys from an S3 bucket starting from the last Key
    @param bucket (string) the name of the bucket that contains the statefile
    @param region (string) the region of the S3 bucket
    @param startAfter (string) the S3 key that the list_objects call should start after
    @returns: a list of S3 keys and a boolian value stating if the list_object call was truncated
    """
    s3KeyList = []
    response = client('s3', region).list_objects_v2(Bucket=bucket, StartAfter=startAfter)
    for value in response["Contents"]:
      s3KeyList.append(value["Key"])
    return (s3KeyList, response["IsTruncated"])

def filter_statefiles(s3KeyList, searchArgs):
    """
    Takes a list of s3 keys and a map of search arguments and filters the list accordingly
    @param s3KeyLiat (list) a list of statefiles paths
    @param searchArgs (dict) a list of key value pairs that will be used to filter the state paths
    @returns: a list of filtered state paths
    """
    searchPattern = ''
    filteredStatefiles = []
    for key, value in searchArgs.items():
      if key is 'stack':
        searchPattern = ('%s(?=.*%s(=|:/)%s/stack.tfstate)' % (searchPattern, key, value))
      else:
        searchPattern = ('%s(?=.*%s(=|:/)%s/)' % (searchPattern, key, value))
    searchPattern = re.compile('^' + searchPattern + '.*$')
    for key in s3KeyList:
      testKey = re.search(searchPattern, key)
      if testKey is not None:
        filteredStatefiles.append(StateFile(testKey.group()))
    return filteredStatefiles

def delete_old_statefiles(statefiles, bucket):
    """
    Deletes a list of previously copied, statefiles form a s3 bucket
    @param statefiles (list) a list of s3 keys
    @param bucket (string) the bucket that contains the s3 keys
    @returns: a list of the statefiles that weren't deleted
    """

    failedCopy = []
    statesToDelete = []
    for state in statefiles:
      if state.copied is False:
        failedCopy.append(state.oldPath)
      else:
        statesToDelete.append({'Key':state.oldPath})
    # Splitting into lists of 1000 keys, due to api limit.
    splitList = [statesToDelete[x:x+1000] for x in range(0, len(statesToDelete), 1000)]
    for oldPathList in splitList:
      response = client('s3').delete_objects(Bucket=bucket, Delete={'Objects':oldPathList})
    return(failedCopy)

# Functions for coloring terminal output.
def print_red(text): print("\033[91m {}\033[00m" .format(text))
def print_green(text): print("\033[92m {}\033[00m" .format(text))

def fetch_and_filter_statefiles(searchArgs, bucket, region):
    """
    Fetches all statefiles paths from s3 bucket and filters them
    @param bucket (string) s3 bucket that contains the statefiles
    @param region (string) the region if the s3 bucket
    @param searchArgs (dict) a list of key value pairs that will be used to filter the state paths
    @returns: a list of filtered state paths
    """
    isTruncated = True
    stateFiles = []
    lastKey = ""
    while isTruncated:
      s3Keys, isTruncated = fetch_statefiles(bucket, region, lastKey)
      stateFiles = stateFiles + s3Keys
      lastKey = stateFiles[-1]
    return filter_statefiles(stateFiles, searchArgs)

def plan_new_statefile_path(replaceArgs, filteredStateFiles):
    """
    Takes a list of filtered statefiles keys, creates new path keys and prints both
    @param filteredStateFiles (list) a list of statefiles objects
    @param searchArgs (dict) a list of key value pairs that will be used to filter the state paths
    """
    for state in filteredStateFiles:
      state.setNewStatePath(replaceArgs)
      if state.newPath is not None:
        print_red(state.oldPath)
        print_green(state.newPath)

def apply_new_statefile_path(statefilesToUpdate, bucket):
    """
    Takes a list of statefiles paths that needs updating, copy them to the new s3 path and
    deletes the old one
    @param statefilesToUpdate (list) a list of statefiles objects to move (copy&delete)
    @param bucket (string) s3 bucket that contains the statefiles
    """

    applyTest = input("Apply changes?, only 'yes' will be accepted \n")
    if applyTest.lower() == 'yes':
      for state in statefilesToUpdate:
        state.copy(bucket)
      failedCopy = delete_old_statefiles(statefilesToUpdate, bucket)
      if failedCopy:
        print("Didn't copy or delete:", *failedCopy, sep='\n')

def main():
    parser = argparse.ArgumentParser(description='Migrates terraform state files')
    parser.add_argument("-s", "--search", action=NameValuePair, nargs='*', metavar='key=value', required=True,
                        help="A space delimited list of key=values pairs, accepted values are env, account,"
                              "app, branch, brand, region, stack")
    parser.add_argument("-r", "--replace", action=NameValuePair, nargs='*', metavar='key=value',
                        help="Optional, a space delimited list of key=values pairs, accepted values are env,"
                              "account, app, branch, brand, region, stack")
    parser.add_argument("-a", "--apply", action='store_true', help="When specified will trigger state file"
                        "move, will just print otherwise")
    parser.add_argument("--region", type=str, default='eu-central-1', help="S3 bucket region," 
                        "defaults to eu-central-1")
    parser.add_argument("--bucket", type=str, default='beamly-tf-state', help="S3 bucket to use,"
                        "defaults to beamly-tf-state")

    args = parser.parse_args()

    filteredStateFiles = fetch_and_filter_statefiles(args.search, args.bucket, args.region)
    if args.replace is not None:
      plan_new_statefile_path(args.replace, filteredStateFiles)
      if args.apply is True:
        apply_new_statefile_path(filteredStateFiles, args.bucket)
    else:
      for state in filteredStateFiles:
        print(state.oldPath)

if __name__ == "__main__":
    main()
