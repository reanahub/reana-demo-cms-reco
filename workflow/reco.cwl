class: CommandLineTool
cwlVersion: v1.0

requirements:
  - class: DockerRequirement
    dockerPull: cmsopendata/cmssw_5_3_32

baseCommand:
  - /bin/zsh

inputs:
  library: File
  build_file: File
  validation_script: File

arguments:
  - position: 0
    prefix: '-c'
    valueFrom: |
      source /opt/cms/cmsset_default.sh
      scramv1 project CMSSW CMSSW_5_3_32
      cd CMSSW_5_3_32/src
      eval `scramv1 runtime -sh`
      mkdir Reconstruction && cd Reconstruction
      mkdir Validation && cd Validation
      cmsDriver.py reco -s RAW2DIGI,L1Reco,RECO,USER:EventFilter/HcalRawToDigi/hcallaserhbhehffilter2012_cff.hcallLaser2012Filter --data --filein='root://eospublic.cern.ch//eos/opendata/cms/Run2012B/SingleMu/RAW/v1/000/194/051/D66F223A-6A9C-E111-AF57-003048F118D4.root' --conditions FT_53_LV5_AN1::All --eventcontent AOD  --no_exec --python reco_cmsdriver.py
      sed -i 's/from Configuration.AlCa.GlobalTag import GlobalTag/process.GlobalTag.connect = cms.string("sqlite_file:\/cvmfs\/cms-opendata-conddb.cern.ch\/FT_53_LV5_AN1_RUNA.db")/g' reco_cmsdriver.py
      sed -i 's/# Other statements/from Configuration.AlCa.GlobalTag import GlobalTag/g' reco_cmsdriver.py
      sed -i "s/process.GlobalTag = GlobalTag(process.GlobalTag, 'FT_53_LV5_AN1::All', '')/process.GlobalTag.globaltag = 'FT_53_LV5_AN1::All'/g" reco_cmsdriver.py
      ln -sf /cvmfs/cms-opendata-conddb.cern.ch/FT_53_LV5_AN1_RUNA FT_53_LV5_AN1
      ln -sf /cvmfs/cms-opendata-conddb.cern.ch/FT_53_LV5_AN1_RUNA.db FT_53_LV5_AN1_RUNA.db
      ls -l
      ls -l /cvmfs/
      cmsRun reco_cmsdriver.py
      mkdir src
      scp ../../../../../../src/$(inputs.library.basename) ./src
      scp ../../../../../../$(inputs.build_file.basename) .
      scp ../../../../../../$(inputs.validation_script.basename) .
      scram b
      cmsRun $(inputs.validation_script.basename)

outputs:
  - id: result.root
    type: File
    outputBinding:
      glob: CMSSW_5_3_32/src/Reconstruction/Validation/reco_RAW2DIGI_L1Reco_RECO_USER.root
  - id: histo.root
    type: File
    outputBinding:
      glob: CMSSW_5_3_32/src/Reconstruction/Validation/histodemo.root
  - id: reco.log
    type: stdout

stdout: reco.log