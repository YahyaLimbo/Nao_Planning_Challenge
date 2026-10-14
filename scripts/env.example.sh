export PYNAOQI_HOME="${HOME}/opt/pynaoqi-python2.7-2.8.7.4-linux64"
export PYTHONPATH="${PYNAOQI_HOME}:${PYNAOQI_HOME}/lib/python2.7/site-packages:${PYTHONPATH:-}"
export LD_LIBRARY_PATH="${PYNAOQI_HOME}:${PYNAOQI_HOME}/lib:${LD_LIBRARY_PATH:-}"
export NAO_IP=127.0.0.1
export NAO_PORT=61476
