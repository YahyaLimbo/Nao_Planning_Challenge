
RUN apt-get -o Acquire::Retries=5 update \
 && apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
        ca-certificates \
        curl \
        dos2unix \
        file \
        locales \
        procps \
 && rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8

ARG PYNAOQI_GLOB=*pynaoqi*linux*.tar.gz
ARG NAOQI_SDK_GLOB=*naoqi-sdk*linux*.tar.gz

COPY vendor/ /tmp/vendor/

RUN set -eu; \
    mkdir -p /opt/naoqi; \
    py_tar="$(ls /tmp/vendor/${PYNAOQI_GLOB} 2>/dev/null | head -n1 || true)"; \
    if [ -z "$py_tar" ]; then \
        echo "ERROR: no pynaoqi tarball matching '${PYNAOQI_GLOB}' in ./vendor"; \
        echo "       see vendor/README.md"; \
        exit 1; \
    fi; \
    echo "==> extracting $py_tar"; \
    tar -xzf "$py_tar" -C /opt/naoqi; \
    ln -s "$(ls -d /opt/naoqi/pynaoqi-* | head -n1)" /opt/naoqi/pynaoqi; \
    sdk_tar="$(ls /tmp/vendor/${NAOQI_SDK_GLOB} 2>/dev/null | head -n1 || true)"; \
    if [ -n "$sdk_tar" ]; then \
        echo "==> extracting $sdk_tar"; \
        tar -xzf "$sdk_tar" -C /opt/naoqi; \
        ln -s "$(ls -d /opt/naoqi/naoqi-sdk-* | head -n1)" /opt/naoqi/sdk; \
    else \
        echo "==> no naoqi-sdk tarball found: the 'sim' service will not work,"; \
        echo "    use Choregraphe's virtual robot on the host instead."; \
    fi; \
    rm -rf /tmp/vendor

RUN set -eu; \
    so="$(find /opt/naoqi/pynaoqi/ -maxdepth 5 -name '*.so' 2>/dev/null | head -n1 || true)"; \
    arch=""; \
    if [ -n "$so" ]; then \
        case "$(file -b "$so")" in \
            *"ELF 32-bit"*) arch=i386 ;; \
            *"ELF 64-bit"*) arch=amd64 ;; \
        esac; \
        echo "==> $so -> $arch"; \
    fi; \
    if [ -z "$arch" ]; then \
        case "$(readlink -f /opt/naoqi/pynaoqi)" in \
            *linux32*) arch=i386 ;; \
            *) arch=amd64 ;; \
        esac; \
        echo "==> no .so found, guessing $arch from the directory name"; \
    fi; \
    echo "$arch" > /opt/naoqi/sdk-arch; \
    suffix=""; \
    if [ "$arch" = "i386" ]; then \
        dpkg --add-architecture i386; \
        suffix=":i386"; \
    fi; \
    apt-get -o Acquire::Retries=5 update; \
    apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
        python2.7${suffix} \
        libpython2.7${suffix} \
        libssl1.0.0${suffix} \
        libxml2${suffix} \
        libffi6${suffix} \
        libasound2${suffix} \
        libusb-1.0-0${suffix} \
        libjpeg-turbo8${suffix} \
        libpng12-0${suffix}; \
    if [ "$arch" = "i386" ]; then \
        apt-get -o Acquire::Retries=5 install -y --no-install-recommends libstdc++6:i386; \
    fi; \
    rm -rf /var/lib/apt/lists/*; \
    ln -sf /usr/bin/python2.7 /usr/bin/python; \
    python --version

ENV PYNAOQI_HOME=/opt/naoqi/pynaoqi \
    NAOQI_SDK_HOME=/opt/naoqi/sdk \
    PYTHONPATH=/opt/naoqi/pynaoqi:/opt/naoqi/pynaoqi/lib/python2.7/site-packages \
    LD_LIBRARY_PATH=/opt/naoqi/pynaoqi:/opt/naoqi/pynaoqi/lib:/opt/naoqi/sdk/lib \
    PATH=/opt/naoqi/sdk:/opt/naoqi/sdk/bin:/usr/local/bin:/usr/bin:/bin \
    PYTHONDONTWRITEBYTECODE=1

RUN python -c "import naoqi, almath, motion; print('import naoqi OK: %s' % naoqi.__file__)"
RUN mkdir -p /home/nao && chmod 1777 /home/nao
ENV HOME=/home/nao

ENV NAO_IP=sim \
    NAO_PORT=9559

COPY docker/entrypoint-sim.sh /usr/local/bin/entrypoint-sim
RUN chmod +x /usr/local/bin/entrypoint-sim

WORKDIR /workspace
CMD ["bash"]
