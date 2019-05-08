#!/usr/bin/python3

# This script will lookup all pipeline with a pipeline group, dissassociate them from any environments and the brute over them until they're all gone. Mwahahahahaha.
# The brute force isn't usually required because the script will delete pipelines in the reverse order they are returned from the API. Which usually means they are deleted in descending chronological order.

import argparse
import requests
import boto3
import json

from termcolor import colored

GOCD_URL = "http://goserver.go.beamly.com:8153/go/api/"

class PipelineGroupBlitz():

    def __init__(self):
        """
        Execute the pipeline group
        """
        self.set_script_arguments()

        self.gocd_credentials = self.get_gocd_credentials()

        self.gocd_request = GocdRequest(self.gocd_credentials["username"], self.gocd_credentials["password"])

        self.pipelines = self.get_gocd_pipeline_group_pipelines()

        self.gocd_environments = self.get_gocd_environments()

        if self.args.dryrun == False:
            self.gocd_environment_pipelines = self.disassociate_pipelines_from_environments()
            self.brute_force_pipeline_deletion()
        else:
            self.print_pipelines_to_delete()

    def set_script_arguments(self):
        """
        Return a collection of arguments passed in when executing this script
        """
        parser = argparse.ArgumentParser(description="This script will lookup all pipeline with a pipeline group, dissassociate them from any environments and the brute over them until they're all gone. Mwahahahahaha.")

        parser.add_argument("-g", "--group", type=str, required=True, help="The name of the pipeline group which should be scrapped")
        parser.add_argument("-d", "--dryrun", action='store_true', help="Is this a dryrun?")

        self.args = parser.parse_args()

    def get_gocd_credentials(self):
        """
        Fetch GoCD credentials from SSM of the Webhop Live AWS account. Return these as a dictionary containing 'username' and 'password'
        @return (dict) Contains a username and password which can be used to authenticate against GoCD
        """
        ssm = boto3.client('ssm', region_name='eu-central-1')

        response = ssm.get_parameters(
            Names=["gocd-api-credentials"],
            WithDecryption=True
        )
        
        return json.loads(response['Parameters'][0]['Value'])
    
    def get_gocd_pipeline_group_pipelines(self):
        """
        Fetch a list of all pipelines within a pipeline group
        @return (list) A list of all pipelines within a pipeline group, where each pipeline is a dict containing a the pipeline name and url
        """
        response = self.gocd_request.send("get", "admin/pipeline_groups/{0}".format(self.args.group), "v1")
        
        def get_pipeline_config(pipeline):
            """
            Fetch pipeline config from GoCD and return the pipeline name and url in a dictionary
            @param pipeline (dict) A pipeline dict returned from the GoCD API
            @return (dict) A dict containing a pipeline name and url
            """
            pipeline_response = self.gocd_request.send("get", "admin/pipelines/{0}".format(pipeline["name"]), "v6")

            return { "name": pipeline["name"], "url": pipeline["_links"]["self"]["href"] }
        
        return map(get_pipeline_config, response["pipelines"])

    def get_gocd_environments(self):
        """
        Fetch a list of GoCD environments from the API along with the associated pipeline names
        @return (list) a list of all GoCD environments, where each environment is a dict containing the name and a list of pipeline names the environment has
        """
        response = self.gocd_request.send("get", "admin/environments", "v2")

        def process_environments(environment):
            """
            Given an environemt dictionary from a GoCD API response, check if any of the pipeline urls match any of the pipeline urls 
            in our pipeline group. Return a dictionary of each environment, with the pipelines that matched.
            @param environment (dict) A GoCD environment dict returned from the GoCD API
            @return (dict) a dict containing the name and a list of pipeline names for a gocd environment
            """
            pipelines = []

            for environment_pipeline in environment["pipelines"]:
                pipeline_url = environment_pipeline["_links"]["self"]["href"]

                if ([pipeline for pipeline in self.pipelines if pipeline['url'] == pipeline_url]):
                    pipelines.append(environment_pipeline["name"])

            return { "name": environment["name"], "pipelines": pipelines }
        
        return map(process_environments, response["_embedded"]["environments"])

    def disassociate_pipelines_from_environments(self):
        """
        Send multiple requests to GoCD to disassociate all pipelines from all environments
        """
        for environment in self.gocd_environments:
            if environment["pipelines"]:
                request_body = {
                    "pipelines": {
                        "remove": environment["pipelines"]
                    }
                }

                response = self.gocd_request.send("patch", "admin/environments/{0}".format(environment["name"]), "v2", request_body)

    def brute_force_pipeline_deletion(self):
        """
        This function will try to delete pieplines in the reverse order they are returned from the API. Which usually means they are deleted in descending chronological order.
        Sometimes, this may not be the case and pipelines could remain undeleted, so we make sure to loop over all pipelines until they're all gone. 
        return (bool) This will return true as soon as all pipelines have been deleted
        """
        pipeline_names = map(lambda pipeline: pipeline["name"], self.pipelines)

        final_pipeline_names = list(pipeline_names)
        
        for i in range(0, len(pipeline_names)):
            for pipeline in reversed(pipeline_names):
                if pipeline in final_pipeline_names:
                    res = self.gocd_request.send("delete", "admin/pipelines/{0}".format(pipeline), "v6")

                    if res.status_code == 200:
                        print colored("Pipeline {0} -> Deleted".format(pipeline), "red")

                        final_pipeline_names.remove(pipeline)

                        if len(final_pipeline_names) == 0:
                            return
                    else:
                        print colored("Pipeline {0} -> Unsuccessfully deleted this time".format(pipeline), "yellow")
    
    def print_pipelines_to_delete(self):
        """
        Print out what pipelines would be deleted if this wasn't a dry run
        """
        print colored("Pipelines to be deleted:", "blue")

        for pipeline in self.pipelines:
            print colored(pipeline["name"], "yellow")
            
class GocdRequest():

    def __init__(self, username, password):
        """
        Initialise object with GoCD username and password
        """
        self.username = username
        self.password = password

    def get(self, endpoint, endpoint_version, headers):
        """
        Send a GET request to GoCD
        return (object) The request modules Response object
        """
        return requests.get(GOCD_URL + endpoint, auth=(self.username, self.password), headers=headers).json()

    def patch(self, endpoint, endpoint_version, headers, request_body = {}):
        """
        Send a PATCH request to GoCD
        return (object) The request modules Response object
        """
        return requests.patch(GOCD_URL + endpoint, auth=(self.username, self.password), headers=headers, json=request_body)

    def delete(self, endpoint, endpoint_version, headers):
        """
        Send a PATCH request to GoCD
        return (object) The request modules Response object
        """
        return requests.delete(GOCD_URL + endpoint, auth=(self.username, self.password), headers=headers)

    def send(self, method, endpoint, endpoint_version, request_body = {}):
        """
        Send a Request to GoCD using the infortmation provided
        return (object) The request modules Response object
        """
        headers = {
            "Accept": "application/vnd.go.cd." + endpoint_version + "+json",
            "Content-Type": "application/json"
        }

        if (method == "get"):
            return self.get(endpoint, endpoint_version, headers)
        elif (method == "patch"):
            return self.patch(endpoint, endpoint_version, headers, request_body)
        elif (method == "delete"):
            return self.delete(endpoint, endpoint_version, headers)
        else:
            raise Exception("Invalid method ({0}) provided".format(method)) 

if __name__ == "__main__":
    PipelineGroupBlitz()
