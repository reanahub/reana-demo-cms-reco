====================================
 REANA example - CMS reconstruction
====================================

.. image:: https://img.shields.io/travis/reanahub/reana-demo-cms-reco.svg
   :target: https://travis-ci.org/reanahub/reana-demo-cms-reco

.. image:: https://badges.gitter.im/Join%20Chat.svg
   :target: https://gitter.im/reanahub/reana?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

.. image:: https://img.shields.io/github/license/reanahub/reana-demo-cms-reco.svg
   :target: https://raw.githubusercontent.com/reanahub/reana-demo-alice-cms-reco/master/LICENSE


About
======
This REANA reproducible analysis example demonstrates the reconstruction
procedure of the CMS collaboration from `raw data <http://opendata.cern.ch/search?page=1&size=20&experiment=CMS&file_type=raw>`_
to `Analysis Object Data (AOD) <https://twiki.cern.ch/twiki/bin/view/CMSPublic/WorkBookDataFormats#AoD>`_.

The workflow consists of the steps need for the samples reconstruction, as taken
from the `CMS legacy validation repo <https://github.com/cms-legacydata-validation/RAWToAODValidation/tree/master>`_.

Reconstruction procedure
=========================

1 & 2. Input data and Analysis code
------------------------------------

Any raw input data from the `CERN open data platform <http://opendata.cern.ch/search?page=1&size=20&experiment=CMS&type=Dataset&subtype=Collision&subtype=Derived&subtype=Simulated&file_type=raw>`_
should be valid for reconstruction. In this example, the input is taken from:
`root://eospublic.cern.ch//eos/opendata/cms/Run2011A/DoubleElectron/RAW/v1/000/160/433/C046161E-0D4E-E011-BCBA-0030487CD906.root`

The reconstruction step can be repeated with a configuration file that depends
on the analyzed data, e.g. `this example <http://opendata.cern.ch/record/43>`_,
or by creating our own configuration file (created in a CMS VM) and then
changing the script accordingly:

.. code-block:: console

    cmsDriver.py reco -s RAW2DIGI,L1Reco,RECO,USER:EventFilter/HcalRawToDigi/hcallaserhbhehffilter2012_cff.hcallLaser2012Filter --data --conditions FT_R_53_LV5::All --eventcontent AOD --customise Configuration/DataProcessing/RecoTLR.customisePrompt --no_exec --python reco_cmsdriver2011.py



3. Compute environment
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

However, for `reana`, the condition database on CVMFS can be accessed with any
container, the only requirement is that the user should specify the necessary
CVMFS volumes to be live-mounted in the `reana.yaml` resource section, as
described `here <https://reana.readthedocs.io/en/latest/userguide.html#declare-necessary-resources>`_.


4. Analysis workflow
--------------------

First, we have to set up the environment variables accordingly for the
`CMS SW <http://cms-sw.github.io/>`_. Although this is done in the docker
image, `reana` overrides them and they need to be reset. This is done by
copying the `cms entrypoint.sh script <https://github.com/clelange/cmssw-docker/blob/master/standalone/entrypoint.sh>`_:

.. code-block:: console

      $ source /opt/cms/cmsset_default.sh
      $ scramv1 project CMSSW CMSSW_5_3_32
      $ cd CMSSW_5_3_32/src
      $ eval `scramv1 runtime -sh`


The actual commands that are needed to carry out the analysis in the CMS
specific environment are then:

.. code-block:: console

      $ scram b
      $ ln -sf /cvmfs/cms-opendata-conddb.cern.ch/FT_53_LV5_AN1_RUNA FT_53_LV5_AN1
      $ ln -sf /cvmfs/cms-opendata-conddb.cern.ch/FT_53_LV5_AN1_RUNA.db FT_53_LV5_AN1_RUNA.db
      $ ls -l
      $ ls -l /cvmfs/
      $ cmsRun reco_cmsdriver2011.py


5. Output results
-----------------

The demo will create ROOT files containing data in the AOD format specified
above.

Running the example on REANA cloud
==================================

When finished, the

.. code-block:: console

    $ # create new virtual environment
    $ virtualenv ~/.virtualenvs/myreana
    $ source ~/.virtualenvs/myreana/bin/activate
    $ # install REANA client
    $ pip install reana-client
    $ # connect to some REANA cloud instance
    $ export REANA_SERVER_URL=https://reana.cern.ch/
    $ export REANA_ACCESS_TOKEN=XXXXXXX
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
