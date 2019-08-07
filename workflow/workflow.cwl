#!/usr/bin/env cwl-runner

# Note that if you are working on the analysis development locally, i.e. outside
# of the REANA platform, you can proceed as follows:
#
#   # ToDo: check these local commands
#   $ cd reana-demo-cms-reco
#   $ mkdir cwl-local-run
#   $ cd cwl-local-run
#   $ cp -a ../workflow/input.yml .
#   $ cp -a ../reco_cmsdriver2011.py .
#   $ cwltool --quiet --outdir="../results" ../workflow/workflow.cwl input.yml


cwlVersion: v1.0
class: Workflow

inputs:
  repo_link: string
  repo_name: string
  year: int
  dataset_name: string
  reco_tool: File

outputs:
  DoubleMu.root:
    type: File
    outputSource:
      step1/DoubleMu.root
  step1.log:
    type: File
    outputSource:
      step1/step1.log


steps:
  step1:
    run: step1.cwl
    in:
      repo_link: repo_link
      repo_name: repo_name
      year: year
      dataset_name: dataset_name
      reco_tool: reco_tool
    out: [DoubleMu.root, step1.log]
