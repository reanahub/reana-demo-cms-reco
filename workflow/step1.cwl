class: CommandLineTool
cwlVersion: v1.0

requirements:
  - class: DockerRequirement
    dockerPull: cmsopendata/cmssw_5_3_32

baseCommand:
  - /bin/zsh

inputs:
  - id: dataset_name
    type: string
  - id: repo_link
    type: string
  - id: repo_name
    type: string
  - id: year
    type: int
  - id: reco_tool
    type: File

arguments:
  - position: 0
    prefix: '-c'
    valueFrom: |
      source /opt/cms/cmsset_default.sh ;\
      scramv1 project CMSSW CMSSW_5_3_32 ;\
      cd CMSSW_5_3_32/src ;\
      eval `scramv1 runtime -sh` ;\
      scp ../../../../$(inputs.reco_tool.basename) . ;\
      cmsRun reco_RAW2DIGI_L1Reco_RECO_USER.root

outputs:
  - id: DoubleMu.root
    type: File
    outputBinding:
      glob: CMSSW_5_3_32/src/reco_RAW2DIGI_L1Reco_RECO_USER.root
  - id: step1.log
    type: stdout

stdout: step1.log
