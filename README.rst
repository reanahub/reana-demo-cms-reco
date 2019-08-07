====================================
 REANA example - CMS reconstruction
====================================

.. image:: https://badges.gitter.im/Join%20Chat.svg
   :target: https://gitter.im/reanahub/reana?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

.. image:: https://img.shields.io/github/license/reanahub/reana-demo-cms-reco.svg
   :target: https://raw.githubusercontent.com/reanahub/reana-demo-cms-reco/master/LICENSE


About
======
This REANA reproducible analysis example demonstrates the reconstruction
procedure of the CMS collaboration from `raw data <http://opendata.cern.ch/search?page=1&size=20&experiment=CMS&file_type=raw>`_
to `Analysis Object Data (AOD) <https://twiki.cern.ch/twiki/bin/view/CMSPublic/WorkBookDataFormats#AoD>`_,
for the `SingleMu 2012 data <http://opendata.cern.ch/record/63>`_.
Running the commands will create ROOT files containing data in the AOD format
specified above.

The workflow consists of the steps need for the samples reconstruction, as taken
from the `CMS legacy validation repo <https://github.com/cms-legacydata-validation/RAWToAODValidation/tree/master>`_.

Reconstruction procedure
=========================

1. Input data
--------------

Any raw input data from the `CERN open data platform <http://opendata.cern.ch/search?page=1&size=20&experiment=CMS&type=Dataset&subtype=Collision&subtype=Derived&subtype=Simulated&file_type=raw>`_
should be valid for reconstruction. In this example, the input is taken from:
`root://eospublic.cern.ch//eos/opendata/cms/Run2012B/SingleMu/RAW/v1/000/194/051/D66F223A-6A9C-E111-AF57-003048F118D4.root`

The reconstruction step can be repeated with a configuration file that depends
on the analyzed data, e.g. `this example <http://opendata.cern.ch/record/43>`_,
or by creating our own configuration file (created in a CMS VM) and then
changing the script accordingly:

.. code-block:: console

    $ cmsDriver.py reco -s RAW2DIGI,L1Reco,RECO,USER:EventFilter/HcalRawToDigi/hcallaserhbhehffilter2012_cff.hcallLaser2012Filter --data --conditions FT_R_53_LV5::All --eventcontent AOD --customise Configuration/DataProcessing/RecoTLR.customisePrompt --no_exec --python reco_cmsdriver2011.py

2. Compute environment
----------------------
In order to be able to rerun the analysis even several years in the future, we
need to "encapsulate the current compute environment", for example to freeze the
software package versions our analysis is using. We shall achieve this by
preparing a `Docker <https://www.docker.com/>`_ container image for our analysis
steps.

This analysis example runs within the `CMSSW <http://cms-sw.github.io/>`_
analysis framework that was packaged for Docker in `cmsopendata
<https://hub.docker.com/u/cmsopendata>`_. The different images corresponds to
data sets taken in different years. Instructions can be found under
`this repo <http://opendata.cern.ch/docs/cms-guide-docker>`_.

Moreover, the re-reconstruction task needs access run-time to the condition
database and inside a `CMS VM <http://opendata.cern.ch/search?page=1&size=20&q=virtual%20machine&subtype=VM&type=Environment&experiment=CMS>`_,
this is achieved with the commands:

.. code-block:: console

    $ ln -sf /cvmfs/cms-opendata-conddb.cern.ch/FT_53_LV5_AN1_RUNA FT_53_LV5_AN1
    $ ln -sf /cvmfs/cms-opendata-conddb.cern.ch/FT_53_LV5_AN1_RUNA.db FT_53_LV5_AN1_RUNA.db

For *reana*, the condition database on CVMFS can be accessed with any
container, the only requirement is that the user should specify the necessary
CVMFS volumes to be live-mounted in the `reana.yaml` resource section, as
described `here <https://reana.readthedocs.io/en/latest/userguide.html#declare-necessary-resources>`_.


3. Workflow
-----------------
The workflow can be logically divided into several parts:

0. Upload all files.
    Some files cannot be generated at run time and need to be uploaded.

.. code-block:: console

    inputs:
      files:
        - src/PhysicsObjectsHistos.cc
        - BuildFile.xml
        - demoanalyzer_cfg.py

1. Fix the CMS SW environment variables manually.
    First, we have to set up the environment variables accordingly for the
    `CMS SW <http://cms-sw.github.io/>`_. Although this is done in the docker
    image, `reana` overrides them and they need to be reset. This is done by
    invoking the `cms entrypoint.sh script <https://github.com/clelange/cmssw-docker/blob/master/standalone/entrypoint.sh>`_
    commands.

    See also this `issue <https://github.com/reanahub/reana-demo-cms-reco/issues/2>`_.

.. code-block:: console

    $ source /opt/cms/cmsset_default.sh
    $ scramv1 project CMSSW CMSSW_5_3_32
    $ cd CMSSW_5_3_32/src
    $ eval `scramv1 runtime -sh`

2. Create the specific CMS path.
    CMS specific data analysis framework requires two directory levels.
    See also `this issue <https://github.com/reanahub/reana-demo-cms-reco/issues/8>`_.

.. code-block:: console

    $ mkdir Reconstruction && cd Reconstruction
    $ mkdir Validation && cd Validation

3. Create the reconstruction file.
    See also `this repo <https://github.com/cms-legacydata-validation/RAWToAODValidation/tree/2012>`_.

.. code-block:: console

    $ cmsDriver.py reco -s RAW2DIGI,L1Reco,RECO,USER:EventFilter/HcalRawToDigi/hcallaserhbhehffilter2012_cff.hcallLaser2012Filter --data --filein='root://eospublic.cern.ch//eos/opendata/cms/Run2012B/SingleMu/RAW/v1/000/194/051/D66F223A-6A9C-E111-AF57-003048F118D4.root' --conditions FT_53_LV5_AN1::All --eventcontent AOD --customise Configuration/DataProcessing/RecoTLR.customisePrompt --no_exec --python reco_cmsdriver.py

4. Adjust the reconstruction file to the specific data file.
    Although generated using parameters, the reconstruction file still requires
    changes.

.. code-block:: console

    $ sed -i 's/from Configuration.AlCa.GlobalTag import GlobalTag/process.GlobalTag.connect = cms.string("sqlite_file:\/cvmfs\/cms-opendata-conddb.cern.ch\/FT_53_LV5_AN1_RUNA.db")/g' reco_cmsdriver.py
    $ sed -i 's/# Other statements/from Configuration.AlCa.GlobalTag import GlobalTag/g' reco_cmsdriver.py
    $ sed -i "s/process.GlobalTag = GlobalTag(process.GlobalTag, 'FT_53_LV5_AN1::All', '')/process.GlobalTag.globaltag = 'FT_53_LV5_AN1::All'/g" reco_cmsdriver.py

5. Link the CVMFS files.
    The `ls -l` commands are explicitly needed to make sure that the
    `cms-opendata-conddb.cern.ch` directory has actually expanded in the image,
    according to `this guide <http://opendata.cern.ch/docs/cms-guide-for-condition-database>`_.
    See also `this issue <https://github.com/reanahub/reana-demo-cms-reco/issues/4>`_.

.. code-block:: console

    $ ln -sf /cvmfs/cms-opendata-conddb.cern.ch/FT_53_LV5_AN1_RUNA FT_53_LV5_AN1
    $ ln -sf /cvmfs/cms-opendata-conddb.cern.ch/FT_53_LV5_AN1_RUNA.db FT_53_LV5_AN1_RUNA.db
    $ ls -l
    $ ls -l /cvmfs/

6. Run the reconstruction.
    At this point all environment variables and files should be proper.

.. code-block:: console

    $ cmsRun reco_cmsdriver.py

7. Adjust project structure for validation
    Copy the required files for the next steps.

.. code-block:: console

    $ mkdir src
    $ scp ../../../../src/PhysicsObjectsHistos.cc ./src
    $ scp ../../../../BuildFile.xml .
    $ scp ../../../../demoanalyzer_cfg.py .


8. Run CMS scram command to fix libraries.
    Most importantly, the *BuildFile.xml* has to be inside the directory where
    the *scram* command is executed.

.. code-block:: console

    $ scram b

9. Run the validation file.
    See also `this repo <http://opendata.cern.ch/record/464>`_

.. code-block:: console

    $ cmsRun demoanalyzer_cfg.py


Running the example on REANA cloud
==================================

The following commands set up the *reana* environment:

.. code-block:: console

    $ # create new virtual environment
    $ virtualenv ~/.virtualenvs/myreana
    $ source ~/.virtualenvs/myreana/bin/activate
    $ # install REANA client
    $ pip install reana-client
    $ # connect to some REANA cloud instance
    $ export REANA_SERVER_URL=https://reana.cern.ch/
    $ export REANA_ACCESS_TOKEN=XXXXXXX

The workflow can be completely run using one command:

.. code-block:: console

    $ reana-client run

It basically consists of the following steps (that can also be run
individually):

.. code-block:: console

    $ # create new workflow
    $ reana-client create -f reana.yaml
    $ export REANA_WORKON=workflow
    $ # start computational workflow
    $ reana-client start
    $ # ... should be finished in several hours, depending on the data size
    $ reana-client status
    $ # list workspace files
    $ reana-client ls
    $ # download output results
    $ reana-client download

Contributors
============

The list of contributors to this REANA example in alphabetical order:

- `Daniel Prelipcean <https://orcid.org/0000-0002-4855-194X>`_
- `Kati Lassila-Perini <https://orcid.org/0000-0002-5502-1795>`_
- `Tibor Simko <https://orcid.org/0000-0001-7202-5803>`_
