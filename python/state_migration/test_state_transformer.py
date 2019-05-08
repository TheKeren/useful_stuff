#!/usr/bin/python3

from boto3 import client
from moto import mock_s3
import unittest
from unittest.mock import patch
import state_transformer 

s3MockKeys = ['env:/dev/account=802874480510/brand=atomicparfums/region=eu-central-1/stack=tf-substack-vpc/stack.tfstate',
             'env:/int/account=802874480510/brand=akeneo/region=eu-central-1/stack=tf-substack-vpc/stack.tfstate',
             'env:/live/account=440474553311/brand=evilCorp/region=us-east-1/stack=tf-substack-vpc/stack.tfstate',
             'env:/live/account=440474553311/branch=evilBranch/region=eu-central-1/stack=tf-substack-vpc/stack.tfstate',
             'env:/stage/account=802874480510/brand=opi/region=eu-central-1/stack=tf-substack-vpc/stack.tfstate',
             'env:/int/account=802874480510/app=evilApp/region=eu-central-1/stack=tf-substack-rds/stack.tfstate',
             'env:/stage/account=802874480510/app=kp/brand=wella/region=eu-central-1/stack=tf-substack-rds/stack.tfstate',
             'env:/live/account=802874480510/branch=test/brand=evilCorp/region=us-east-1/stack=tf-substack-ecr/ninja/stack.tfstate',
             'env:/stage/account=802874480510/app=pim/brand=akeneo/region=eu-central-1/stack=tf-substack-ecr/stack.tfstate',
             'env:/dev/account=802874480510/app=site/brand=maxfactor/region=eu-central-1/stack=tf-substack-ecr/stack.tfstate',
             'env:/live/brand=wella/stack=tf-icjapi-wella/pipeline/stack.tfstate',
             'env:/live/brand=wella/stack=tf-icjapi-wella/pipelines/stack.tfstate']

bucket = 'mock-tf-state'
region = 'eu-central-1'


class TestStateTransformer(unittest.TestCase):
    
    @mock_s3
    def test_fetch_statefiles(self):
        s3 = client('s3', region)
        s3.create_bucket(Bucket=bucket)
        for s3Key in s3MockKeys:
          s3.put_object(Bucket=bucket, Key=s3Key, Body='cheeseCake')
        s3ReturnKeys, IsTruncated = state_transformer.fetch_statefiles(bucket, region, "")
        assert sorted(s3ReturnKeys) == sorted(s3MockKeys)
        assert IsTruncated is False 

    def test_filter_statefiles(self):
        searchArgs = {'env':'live',
                      'brand': 'evilCorp'}
        expectedOutput = ['env:/live/account=440474553311/brand=evilCorp/region=us-east-1/stack=tf-substack-vpc/stack.tfstate',
                          'env:/live/account=802874480510/branch=test/brand=evilCorp/region=us-east-1/stack=tf-substack-ecr/ninja/stack.tfstate']
        filteredStatefileObjects = state_transformer.filter_statefiles(s3MockKeys, searchArgs)
        filteredStatefilesPaths = [returnedStateObject.oldPath for returnedStateObject in filteredStatefileObjects]

        assert expectedOutput == filteredStatefilesPaths

    def test_filter_statefiles_stack(self):
        searchArgs = {'stack':'tf-substack-ecr'}
        expectedOutput = ['env:/stage/account=802874480510/app=pim/brand=akeneo/region=eu-central-1/stack=tf-substack-ecr/stack.tfstate',
                          'env:/dev/account=802874480510/app=site/brand=maxfactor/region=eu-central-1/stack=tf-substack-ecr/stack.tfstate']
        filteredStatefileObjects = state_transformer.filter_statefiles(s3MockKeys, searchArgs)
        filteredStatefilesPaths = [returnedStateObject.oldPath for returnedStateObject in filteredStatefileObjects]

        assert expectedOutput == filteredStatefilesPaths

    @mock_s3
    def test_delete_old_statefiles(self):
        s3 = client('s3', region)
        s3.create_bucket(Bucket=bucket)
        mockS3Keys = ['test/path/1', 'test/path/2', 'test/path/3'] 
        stateFileObjects =[]
        for s3Key in mockS3Keys:
          s3.put_object(Bucket=bucket, Key=s3Key, Body='cheeseCake')
          stateFileObjects.append(state_transformer.StateFile(s3Key))
        stateFileObjects[0].copied = False
        notDeletedStates = state_transformer.delete_old_statefiles(stateFileObjects, bucket)
        fetchS3Keys = [s3Response["Key"] for s3Response in s3.list_objects_v2(Bucket=bucket)["Contents"]]
        assert notDeletedStates == fetchS3Keys

    def test_setNewStatePath(self):
        replaceArgs = {'stack':'very/evil/test',
                       'branch':'evilBranch'}
        stateOldPath = 'env:/int/account=802874480510/app=evilApp/region=eu-central-1/stack=tf-substack-rds/stack.tfstate' 
        expectedNewPath = 'env:/int/account=802874480510/app=evilApp/branch=evilBranch/region=eu-central-1/stack=very/evil/test/stack.tfstate' 
        stateObject = state_transformer.StateFile(stateOldPath)
        stateObject.setNewStatePath(replaceArgs)
        assert stateObject.newPath == expectedNewPath
        
    def test_setNewStatePathBadPath(self):
        replaceArgs = {'stack':'very/evil/test',
                       'branch':'evilBranch'}
        stateOldPath = 'env:/live/brand=wella/stack=tf-icjapi-wella/pipeline/stack.tfstate'
        stateObject = state_transformer.StateFile(stateOldPath)
        stateObject.setNewStatePath(replaceArgs)
        assert stateObject.newPath is None

    @mock_s3
    def test_copy(self):
        s3 = client('s3', region)
        s3.create_bucket(Bucket=bucket)
        s3.put_object(Bucket=bucket, Key='test/path/1', Body='cheeseCake')
        stateObject = state_transformer.StateFile('test/path/1')
        stateObject.newPath = 'test/path/2'
        stateObject.copy(bucket)
        fetchS3Keys = [s3Response["Key"] for s3Response in s3.list_objects_v2(Bucket=bucket)["Contents"]]
        assert stateObject.newPath in fetchS3Keys

    @mock_s3
    def test_copy_empty_newPath(self):
        s3 = client('s3', region)
        s3.create_bucket(Bucket=bucket)
        s3.put_object(Bucket=bucket, Key='test/path/1', Body='cheeseCake')
        stateObject = state_transformer.StateFile('test/path/1')
        stateObject.copy(bucket)
        fetchS3Keys = [s3Response["Key"] for s3Response in s3.list_objects_v2(Bucket=bucket)["Contents"]]
        assert fetchS3Keys == ['test/path/1']

    @mock_s3
    def test_fetch_and_filter_statefiles(self):
        searchArgs = {'env':'live',
                      'brand': 'evilCorp'}
        expectedOutput = ['env:/live/account=440474553311/brand=evilCorp/region=us-east-1/stack=tf-substack-vpc/stack.tfstate',
                          'env:/live/account=802874480510/branch=test/brand=evilCorp/region=us-east-1/stack=tf-substack-ecr/ninja/stack.tfstate']
        s3 = client('s3', region)
        s3.create_bucket(Bucket=bucket)
        for s3Key in s3MockKeys:
          s3.put_object(Bucket=bucket, Key=s3Key, Body='cheeseCake')
        filteredStatefileObjects = state_transformer.fetch_and_filter_statefiles(searchArgs, bucket, region)
        filteredStatefilesPaths = [returnedStateObject.oldPath for returnedStateObject in filteredStatefileObjects]
        assert sorted(filteredStatefilesPaths) == sorted(expectedOutput)

    def test_plan_new_statefile_path(self):
        replaceArgs = {'env':'test',
                       'app':'testApp'}
        stateOldPaths = ['env:/int/account=802874480510/app=evilApp/region=eu-central-1/stack=tf-substack-rds/stack.tfstate',
                         'env:/live/brand=wella/stack=tf-icjapi-wella/pipelines/stack.tfstate',
                         'env:/stage/account=802874480510/app=kp/brand=wella/region=eu-central-1/stack=tf-substack-rds/stack.tfstate']
        expectedOutput = ['env:/test/account=802874480510/app=testApp/region=eu-central-1/stack=tf-substack-rds/stack.tfstate',
                          'env:/test/account=802874480510/app=testApp/brand=wella/region=eu-central-1/stack=tf-substack-rds/stack.tfstate']
        statefileObjects = [state_transformer.StateFile(path) for path in stateOldPaths]
        state_transformer.plan_new_statefile_path(replaceArgs, statefileObjects)
        newPaths = [statefile.newPath for statefile in statefileObjects if statefile.newPath is not None]
        assert sorted(newPaths) == sorted(expectedOutput)

    @mock_s3
    def test_apply_new_statefile_path(self):
        expectedOutput = ['new/path/1', 'new/path/2', 'test/path/3']
        s3 = client('s3', region)
        s3.create_bucket(Bucket=bucket)
        mockS3Keys = ['test/path/1', 'test/path/2', 'test/path/3'] 
        stateFileObjects =[]
        for s3Key in mockS3Keys:
          s3.put_object(Bucket=bucket, Key=s3Key, Body='cheeseCake')
          stateFileObjects.append(state_transformer.StateFile(s3Key))
        stateFileObjects[0].newPath = 'new/path/1'
        stateFileObjects[1].newPath = 'new/path/2'
        original_input = __builtins__.input
        __builtins__.input = lambda _: 'yes'
        state_transformer.apply_new_statefile_path(stateFileObjects, bucket)
        fetchS3Keys = [s3Response["Key"] for s3Response in s3.list_objects_v2(Bucket=bucket)["Contents"]]
        assert sorted(expectedOutput) == sorted(fetchS3Keys)

if __name__ == "__main__":
    unittest.main()
