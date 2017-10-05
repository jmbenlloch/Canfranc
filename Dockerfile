FROM ubuntu:16.04

RUN apt-get update && apt-get install lsof net-tools python python-pip inetutils-ping build-essential python-dev git libgl1  vim screen torque-mom torque-pam torque-client torque-server torque-scheduler wget curl hdf5-tools -y
RUN echo 'root:root' | chpasswd

#Add start script for torque
ADD startup.sh /
RUN chmod +x /startup.sh

#Add user
RUN useradd -ms /bin/bash icuser
RUN echo 'icuser:icpass' | chpasswd

#Create directories
RUN mkdir -p /software/ /analysis
RUN chown icuser:icuser /software /analysis
USER icuser

#Install prod and dev versions of IC
RUN git clone https://github.com/nextic/IC /software/IC
RUN git clone https://github.com/nextic/IC /software/IC-dev
#checkout old version from canfranc
RUN cd /software/IC; git reset --hard 8dc4b1c55ce95e169bcb85ec35df3445fc9af9bc
RUN cd /software/IC-dev; git reset --hard eb903c7711357299692179872ef0a1ab3c5284e8

#Data files
RUN mkdir -p /analysis/4730/hdf5/data
ADD data/*h5 /analysis/4730/hdf5/data/

WORKDIR /home/icuser

#Install miniconda
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda3.sh
RUN bash miniconda3.sh -b -p /software/miniconda3
ENV PATH /software/miniconda3/bin:$PATH

#Compile IC & IC-dev
RUN cd /software/IC; bash -c 'source manage.sh install_and_check 3.6'

ADD environment3.6new.yml /software/IC-dev/environment3.6new.yml
RUN conda env create -f /software/IC-dev/environment3.6new.yml
RUN sed -i 's/source activate IC${PYTHON_VERSION}/source activate IC${PYTHON_VERSION}new/g' /software/IC-dev/manage.sh 
RUN cd /software/IC-dev; bash -c 'source manage.sh work_in_python_version 3.6'

#Install miniconda2 for CERES
RUN wget https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh -O miniconda2.sh
RUN bash miniconda2.sh -b -p /home/icuser/miniconda
RUN echo "export PATH=/home/icuser/miniconda/bin:$PATH" >> /home/icuser/.bashrc
ENV PATH /home/icuser/miniconda/bin:$PATH

#Install prod and dev versions of CERES
RUN git clone https://github.com/jmbenlloch/CERES CERES
RUN git clone https://github.com/jmbenlloch/CERES CERES_dev

RUN cd /home/icuser/CERES; git checkout refactor
RUN cd /home/icuser/CERES_dev; git checkout dev
RUN pip install -r /home/icuser/CERES/requirements.txt

#Env Variables for CERES
RUN echo "export PYTHONPATH=/home/icuser/CERES:$PYTHONPATH" >> /home/icuser/.bashrc
RUN echo "export CERESDIR=/home/icuser/CERES" >> /home/icuser/.bashrc
RUN echo "export CERESDEVDIR=/home/icuser/CERES_dev" >> /home/icuser/.bashrc

RUN pip install pytest
ADD tests /home/icuser/tests
#ADD execute_tests.sh /home/icuser/
RUN echo "#!/bin/bash" > /home/icuser/execute_tests.sh
RUN grep export .bashrc >> /home/icuser/execute_tests.sh
RUN echo pytest -v /home/icuser/tests/tests.py >> /home/icuser/execute_tests.sh
RUN chmod +x /home/icuser/execute_tests.sh

USER root

CMD /startup.sh; su icuser; /bin/bash
